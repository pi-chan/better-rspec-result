# frozen_string_literal: true

require "clipboard"
require "fileutils"

module BetterRspecResult
  module UI
    # Handles clipboard operations with fallback to file writing
    class Clipboard
      FALLBACK_FILENAME = "failed_locations.txt"

      def initialize
        # Test clipboard availability
        @clipboard_available = test_clipboard_availability
      end

      # Copy text to clipboard or fallback to file
      # @param text [String] Text to copy
      # @return [Hash] Result with :success, :method, and optional :file_path
      def copy(text)
        if @clipboard_available
          begin
            ::Clipboard.copy(text)
            { success: true, method: :clipboard }
          rescue StandardError
            fallback_to_file(text)
          end
        else
          fallback_to_file(text)
        end
      end

      # Copy all failure locations
      # @param failures [Array<Hash>] Array of failure hashes with file_path and line_number
      # @return [Hash] Result hash
      def copy_failure_locations(failures)
        return { success: false, message: "No failures to copy" } if failures.empty?

        locations = failures.map do |failure|
          "#{failure['file_path']}:#{failure['line_number']}"
        end.join("\n")

        copy(locations)
      end

      # Copy single location
      # @param file_path [String] File path
      # @param line_number [Integer] Line number
      # @param full_path [Boolean] Whether to use full path
      # @return [Hash] Result hash
      def copy_location(file_path, line_number, full_path: false)
        location_path = full_path ? File.expand_path(file_path) : file_path
        location = "#{location_path}:#{line_number}"
        copy(location)
      end

      # Get fallback file path
      # @return [String] Path to fallback file
      def self.fallback_file_path
        File.expand_path("~/.better-rspec-results/#{FALLBACK_FILENAME}")
      end

      private

      def test_clipboard_availability
        ::Clipboard.copy("")
        true
      rescue StandardError
        false
      end

      def fallback_to_file(text)
        file_path = self.class.fallback_file_path
        FileUtils.mkdir_p(File.dirname(file_path))
        File.write(file_path, text)

        {
          success: true,
          method: :file,
          file_path: file_path
        }
      end
    end
  end
end
