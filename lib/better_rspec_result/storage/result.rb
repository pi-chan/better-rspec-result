# frozen_string_literal: true

require "json"

module BetterRspecResult
  module Storage
    # Represents a single RSpec test run result
    class Result
          attr_reader :metadata, :summary, :examples

          def initialize(data)
            @metadata = data["metadata"] || {}
            @summary = data["summary"] || {}
            @examples = data["examples"] || []
          end

          # Returns only failed examples
          def failed_examples
            @failed_examples ||= examples.select { |ex| ex["status"] == "failed" }
          end

          # Returns only passed examples
          def passed_examples
            @passed_examples ||= examples.select { |ex| ex["status"] == "passed" }
          end

          # Returns only pending examples
          def pending_examples
            @pending_examples ||= examples.select { |ex| ex["status"] == "pending" }
          end

          # Calculate success rate as a percentage
          def success_rate
            return 0.0 if example_count.zero?

            (passed_count.to_f / example_count * 100).round(2)
          end

          # Total number of examples
          def example_count
            summary["example_count"] || examples.size
          end

          # Number of failed examples
          def failure_count
            summary["failure_count"] || failed_examples.size
          end

          # Number of passed examples
          def passed_count
            example_count - failure_count - pending_count
          end

          # Number of pending examples
          def pending_count
            summary["pending_count"] || pending_examples.size
          end

          # Duration in seconds
          def duration
            summary["duration"] || 0.0
          end

          # Timestamp of the test run
          def timestamp
            metadata["timestamp"]
          end

          # Convert to hash for JSON serialization
          def to_h
            {
              "metadata" => metadata,
              "summary" => summary,
              "examples" => examples
            }
          end

          # Convert to JSON
          def to_json(*args)
            to_h.to_json(*args)
          end

          # Check if the test run was successful (no failures)
          def success?
            failure_count.zero?
          end

          # Check if the test run had failures
          def failed?
            !success?
          end
        end
      end
    end
