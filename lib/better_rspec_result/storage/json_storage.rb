# frozen_string_literal: true

require "json"
require "fileutils"
require_relative "result"

module BetterRspecResult
  module Storage
    # Handles saving and loading test results to/from JSON files
    class JsonStorage
      DEFAULT_STORAGE_DIRNAME = ".better-rspec-results"
      MAX_RESULTS = 100

      # Directories that should never be used as storage
      # Note: /var/folders is allowed (macOS user temp directory)
      FORBIDDEN_DIRECTORIES = [
        "/etc", "/usr", "/bin", "/sbin", "/lib", "/lib64",
        "/var/log", "/var/lib", "/var/run", "/var/cache",
        "/System", "/Library", "/Applications",
        "/Windows", "/Program Files"
      ].freeze

      class PathTraversalError < SecurityError; end

      attr_reader :storage_dir

      def initialize(storage_dir = nil)
        @storage_dir = validate_storage_path(storage_dir || detect_project_storage_dir)
        ensure_storage_dir_exists
      end

      # Save a result to a JSON file
      # @param result_data [Hash] The result data to save
      # @return [String] Path to the saved file
      def save(result_data)
        timestamp = Time.now.strftime("%Y%m%d-%H%M%S-%6N")
        filename = "rspec-result-#{timestamp}.json"
        filepath = File.join(storage_dir, filename)

        # Write with restricted permissions (owner read/write only)
        File.write(filepath, JSON.pretty_generate(result_data))
        File.chmod(0o600, filepath)
        cleanup_old_results

        filepath
      end

      # Load a result from a JSON file
      # @param filepath [String] Path to the JSON file
      # @return [Result] The loaded result object
      # @raise [PathTraversalError] if filepath is outside storage directory
      def load(filepath)
        validate_filepath_in_storage(filepath)
        data = JSON.parse(File.read(filepath))
        Result.new(data)
      end

      # List all result files sorted by modification time (newest first)
      # @return [Array<String>] Array of file paths
      def list_results
        Dir.glob(File.join(storage_dir, "rspec-result-*.json"))
           .sort_by { |f| File.mtime(f) }
           .reverse
      end

      # Get the latest result file
      # @return [String, nil] Path to the latest result file, or nil if none exist
      def latest_result_file
        list_results.first
      end

      # Load the latest result
      # @return [Result, nil] The latest result object, or nil if none exist
      def latest_result
        latest_file = latest_result_file
        return nil unless latest_file

        load(latest_file)
      end

      # Remove a specific result file
      # @param filepath [String] Path to the file to remove
      # @raise [PathTraversalError] if filepath is outside storage directory
      def remove(filepath)
        validate_filepath_in_storage(filepath)
        FileUtils.rm_f(filepath)
      end

      # Remove all result files
      def clear_all
        list_results.each { |filepath| remove(filepath) }
      end

      # Clean up old results, keeping only the most recent MAX_RESULTS files
      def cleanup_old_results
        results = list_results
        return if results.size <= MAX_RESULTS

        results[MAX_RESULTS..].each { |filepath| remove(filepath) }
      end

      # Get storage directory size in bytes
      # @return [Integer] Total size of all result files
      def storage_size
        list_results.sum { |filepath| File.size(filepath) }
      end

      # Get storage directory size in human-readable format
      # @return [String] Size in KB, MB, or GB
      def storage_size_human
        size = storage_size
        return "#{size} B" if size < 1024

        size_kb = size / 1024.0
        return "#{size_kb.round(2)} KB" if size_kb < 1024

        size_mb = size_kb / 1024.0
        return "#{size_mb.round(2)} MB" if size_mb < 1024

        size_gb = size_mb / 1024.0
        "#{size_gb.round(2)} GB"
      end

      private

      # Detect project root and create storage directory there
      def detect_project_storage_dir
        # Allow override via environment variable
        return validate_storage_path(ENV["BETTER_RSPEC_RESULTS_DIR"]) if ENV["BETTER_RSPEC_RESULTS_DIR"]

        current_dir = Dir.pwd

        # Search for git root or use current directory
        project_root = find_git_root(current_dir) || current_dir

        # Store in tmp directory to avoid cluttering project root
        File.join(project_root, "tmp", DEFAULT_STORAGE_DIRNAME)
      end

      # Validate storage path is safe
      # @param path [String] Path to validate
      # @return [String] The validated path
      # @raise [PathTraversalError] if path is forbidden or a symlink to forbidden location
      def validate_storage_path(path)
        expanded_path = File.expand_path(path)

        # Check against forbidden directories
        FORBIDDEN_DIRECTORIES.each do |forbidden|
          if expanded_path.start_with?(forbidden)
            raise PathTraversalError, "Storage path cannot be in system directory: #{forbidden}"
          end
        end

        # Check if path is a symlink pointing to forbidden location
        if File.symlink?(expanded_path)
          real_path = File.realpath(expanded_path)
          FORBIDDEN_DIRECTORIES.each do |forbidden|
            if real_path.start_with?(forbidden)
              raise PathTraversalError, "Storage path symlink points to forbidden directory"
            end
          end
        end

        expanded_path
      end

      # Validate that a filepath is within the storage directory
      # @param filepath [String] Path to validate
      # @raise [PathTraversalError] if filepath is outside storage directory
      def validate_filepath_in_storage(filepath)
        expanded_filepath = File.expand_path(filepath)
        expanded_storage = File.expand_path(storage_dir)

        # Resolve symlinks for storage directory (it should exist)
        real_storage = File.exist?(expanded_storage) ? File.realpath(expanded_storage) : expanded_storage

        # For the filepath, resolve its parent directory if the file doesn't exist
        if File.exist?(expanded_filepath)
          real_filepath = File.realpath(expanded_filepath)
        else
          # File doesn't exist - resolve the parent directory and append filename
          parent_dir = File.dirname(expanded_filepath)
          filename = File.basename(expanded_filepath)
          real_parent = File.exist?(parent_dir) ? File.realpath(parent_dir) : parent_dir
          real_filepath = File.join(real_parent, filename)
        end

        return if real_filepath.start_with?("#{real_storage}/")

        raise PathTraversalError, "File path must be within storage directory"
      end

      # Find git repository root by searching for .git directory
      def find_git_root(start_dir)
        dir = start_dir

        while dir != File.dirname(dir) # Stop at filesystem root
          return dir if File.directory?(File.join(dir, ".git"))

          dir = File.dirname(dir)
        end

        nil
      end

      def ensure_storage_dir_exists
        FileUtils.mkdir_p(storage_dir)
      end
    end
  end
end
