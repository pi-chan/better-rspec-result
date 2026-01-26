# frozen_string_literal: true

require "time"
require "rspec/core"
require "rspec/core/formatters/base_formatter"
require_relative "storage/json_storage"

module BetterRspecResult
  # Custom RSpec formatter that captures test results in structured format
  class Formatter < RSpec::Core::Formatters::BaseFormatter
        RSpec::Core::Formatters.register self,
          :start,
          :example_passed,
          :example_failed,
          :example_pending,
          :dump_summary,
          :close

        def initialize(output)
          super
          @examples_data = []
          @start_time = nil
        end

        # Called at the start of the test suite
        def start(notification)
          @start_time = Time.now
          @example_count = notification.count
        end

        # Called when an example passes
        def example_passed(notification)
          capture_example(notification, "passed")
        end

        # Called when an example fails
        def example_failed(notification)
          capture_example(notification, "failed")
        end

        # Called when an example is pending
        def example_pending(notification)
          capture_example(notification, "pending")
        end

        # Called at the end of the test suite
        def dump_summary(notification)
          @summary_notification = notification
        end

        # Called when the formatter is closed
        def close(_notification)
          save_results
        end

        private

        # Capture example data
        def capture_example(notification, status)
          example = notification.example
          data = {
            "id" => example.id,
            "description" => example.description,
            "full_description" => example.full_description,
            "status" => status,
            "file_path" => example.metadata[:file_path],
            "line_number" => example.metadata[:line_number],
            "run_time" => example.execution_result.run_time
          }

          # Add exception details for failed examples
          if status == "failed" && example.exception
            data["exception"] = {
              "class" => example.exception.class.name,
              "message" => example.exception.message,
              "backtrace" => format_backtrace(example.exception.backtrace)
            }
          end

          @examples_data << data
        end

        # Format backtrace to include only relevant lines
        def format_backtrace(backtrace)
          return [] unless backtrace

          # Keep first 20 lines to avoid huge JSON files
          backtrace.first(20)
        end

        # Build metadata hash
        def build_metadata
          {
            "version" => BetterRspecResult::VERSION,
            "timestamp" => @start_time.iso8601,
            "command" => $PROGRAM_NAME + " " + ARGV.join(" "),
            "seed" => RSpec.configuration.seed,
            "rspec_version" => RSpec::Core::Version::STRING,
            "ruby_version" => RUBY_VERSION,
            "working_directory" => Dir.pwd
          }
        end

        # Build summary hash
        def build_summary
          return {} unless @summary_notification

          {
            "duration" => @summary_notification.duration,
            "example_count" => @summary_notification.example_count,
            "failure_count" => @summary_notification.failure_count,
            "pending_count" => @summary_notification.pending_count,
            "errors_outside_of_examples_count" => @summary_notification.errors_outside_of_examples_count
          }
        end

        # Save results to JSON file
        def save_results
          result_data = {
            "metadata" => build_metadata,
            "summary" => build_summary,
            "examples" => @examples_data
          }

          storage = Storage::JsonStorage.new
          filepath = storage.save(result_data)

          output.puts "\nBetter RSpec Result saved to: #{filepath}"
        rescue StandardError => e
          output.puts "\nFailed to save Better RSpec Result: #{e.message}"
        end
      end
    end
