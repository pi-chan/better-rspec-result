# frozen_string_literal: true

require "tty-prompt"
require "tty-screen"
require_relative "components/color_scheme"
require_relative "components/formatter"
require_relative "failure_list"

module BetterRspecResult
  module UI
    # Displays interactive list of test result history
    class HistoryList
      def initialize(storage:, prompt:, color_scheme: nil, formatter: nil)
        @storage = storage
        @prompt = prompt
        @color_scheme = color_scheme || Components::ColorScheme.new
        @formatter = formatter || Components::Formatter.new
      end

      def show
        results = load_results

        if results.empty?
          @prompt.say(@color_scheme.dim("No results found."))
          return
        end

        loop do
          choice = show_result_menu(results)
          break if choice == :back

          show_result_detail_menu(choice)
        end
      end

      def load_results
        filepaths = @storage.list_results
        filepaths.map { |filepath| @storage.load(filepath) }
                 .sort_by(&:timestamp)
                 .reverse
      end

      def format_result_item(result)
        status_text = @formatter.format_status(result)
        status_colored = result.success? ? @color_scheme.passed(status_text) : @color_scheme.failed(status_text)

        timestamp = @formatter.format_timestamp(result.timestamp)
        duration = @formatter.format_duration(result.duration)

        "#{status_colored} #{@color_scheme.dim(timestamp)} | " \
          "#{result.example_count} examples, #{result.failure_count} failures | " \
          "#{duration}"
      end

      def show_result_detail_menu(result)
        # Directly show failures if result has failures
        if result.failed?
          show_failures(result)
        else
          # Show summary for passed results
          display_summary(result)
        end
      end

      private

      def show_result_menu(results)
        screen_height = TTY::Screen.height
        per_page = [screen_height - 5, 10].max

        choices = results.map do |result|
          {
            name: format_result_item(result),
            value: result
          }
        end

        choices << { name: @color_scheme.dim("← Back"), value: :back }

        @prompt.select(
          "Select a result:",
          choices,
          per_page: per_page,
          cycle: true
        )
      end

      def build_detail_menu(result)
        choices = [
          { name: "View Summary", value: :view_summary }
        ]

        choices << { name: "View Failed Examples", value: :view_failures } if result.failed?

        choices << { name: @color_scheme.dim("← Back"), value: :back }

        @prompt.select(
          "Result Details:",
          choices
        )
      end

      def handle_detail_choice(choice, result)
        case choice
        when :view_summary
          display_summary(result)
        when :view_failures
          show_failures(result)
        end
      end

      def display_summary(result)
        summary = []
        summary << ""
        summary << @color_scheme.highlight("=" * 60)
        summary << @color_scheme.highlight("Test Result Summary")
        summary << @color_scheme.highlight("=" * 60)
        summary << ""

        summary << "Timestamp: #{@formatter.format_timestamp(result.timestamp)}"
        summary << "Duration: #{@formatter.format_duration(result.duration)}"

        summary << "Command: #{@color_scheme.dim(result.metadata['command'])}" if result.metadata["command"]

        summary << ""

        status_text = @formatter.format_status(result)
        status_colored = result.success? ? @color_scheme.passed(status_text) : @color_scheme.failed(status_text)
        summary << "Status: #{status_colored}"
        summary << "Examples: #{result.example_count}"
        summary << "Failures: #{result.failure_count}"
        summary << "Pending: #{result.pending_count}"
        summary << "Success Rate: #{@color_scheme.success_rate(result.success_rate)}"
        summary << ""

        summary << @color_scheme.dim("Press any key to continue...")

        @prompt.say(summary.join("\n"))
        @prompt.keypress
      end

      def show_failures(result)
        failure_list = FailureList.new(
          result: result,
          prompt: @prompt,
          color_scheme: @color_scheme,
          formatter: @formatter
        )
        failure_list.show
      end
    end
  end
end
