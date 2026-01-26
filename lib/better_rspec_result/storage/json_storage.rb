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

      attr_reader :storage_dir

      def initialize(storage_dir = nil)
        @storage_dir = storage_dir || detect_project_storage_dir
        ensure_storage_dir_exists
      end

      # Save a result to a JSON file
      # @param result_data [Hash] The result data to save
      # @return [String] Path to the saved file
      def save(result_data)
        timestamp = Time.now.strftime("%Y%m%d-%H%M%S-%6N")
        filename = "rspec-result-#{timestamp}.json"
        filepath = File.join(storage_dir, filename)

        File.write(filepath, JSON.pretty_generate(result_data))
        cleanup_old_results

        filepath
      end

      # Load a result from a JSON file
      # @param filepath [String] Path to the JSON file
      # @return [Result] The loaded result object
      def load(filepath)
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
      def remove(filepath)
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
        return ENV["BETTER_RSPEC_RESULTS_DIR"] if ENV["BETTER_RSPEC_RESULTS_DIR"]

        current_dir = Dir.pwd

        # Search for git root or use current directory
        project_root = find_git_root(current_dir) || current_dir

        # Store in tmp directory to avoid cluttering project root
        File.join(project_root, "tmp", DEFAULT_STORAGE_DIRNAME)
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
