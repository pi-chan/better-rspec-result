# frozen_string_literal: true

require "time"

module BetterRspecResult
  module UI
    module Components
      # Provides formatting utilities for display
      class Formatter
        def format_timestamp(timestamp)
          Time.parse(timestamp).strftime("%Y-%m-%d %H:%M:%S")
        rescue ArgumentError
          timestamp
        end

        def format_duration(seconds)
          "#{seconds.round(1)}s"
        end

        def format_file_location(file_path, line_number)
          return file_path unless line_number

          "#{file_path}:#{line_number}"
        end

        def truncate(text, length)
          return text if text.length <= length

          "#{text[0...(length - 3)]}..."
        end

        def format_status(result)
          result.success? ? "PASSED" : "FAILED"
        end
      end
    end
  end
end
