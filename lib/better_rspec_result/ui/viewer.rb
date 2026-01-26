# frozen_string_literal: true

require "tty-prompt"
require_relative "components/color_scheme"
require_relative "components/formatter"
require_relative "history_list"
require_relative "failure_list"
require_relative "key_bindings"

module BetterRspecResult
  module UI
    # Main TUI viewer for Better RSpec Result
    class Viewer
      def initialize(storage:, prompt: nil, color_scheme: nil)
        @storage = storage
        @prompt = prompt || KeyBindings.create_prompt
        @color_scheme = color_scheme || Components::ColorScheme.new
        @formatter = Components::Formatter.new
      end

      def start
        loop do
          choice = show_main_menu
          break if choice == :exit

          handle_menu_choice(choice)
        end
      rescue Interrupt
        # Gracefully handle Ctrl+C
        nil
      end

      def handle_view_latest
        result = @storage.latest_result
        unless result
          @prompt.say(@color_scheme.dim(
            "No results found. Run RSpec with --format BetterRspecResult::Formatter"
          ))
          return
        end

        display_result_summary(result)
      end

      def handle_view_history
        history_list = HistoryList.new(
          storage: @storage,
          prompt: @prompt,
          color_scheme: @color_scheme,
          formatter: @formatter
        )
        history_list.show
      end

      def display_result_summary(result)
        summary = []
        summary << ""
        summary << @color_scheme.highlight("=" * 60)
        summary << @color_scheme.highlight("Test Result Summary")
        summary << @color_scheme.highlight("=" * 60)
        summary << ""

        summary << "Timestamp: #{@formatter.format_timestamp(result.timestamp)}"
        summary << "Duration: #{@formatter.format_duration(result.duration)}"

        if result.metadata["command"]
          summary << "Command: #{@color_scheme.dim(result.metadata["command"])}"
        end

        summary << ""

        status_text = @formatter.format_status(result)
        status_colored = result.success? ? @color_scheme.passed(status_text) : @color_scheme.failed(status_text)
        summary << "Status: #{status_colored}"
        summary << "Examples: #{result.example_count}"
        summary << "Failures: #{result.failure_count}"
        summary << "Pending: #{result.pending_count}"
        summary << "Success Rate: #{@color_scheme.success_rate(result.success_rate)}"
        summary << ""

        @prompt.say(summary.join("\n"))

        if result.failed?
          show_failures = @prompt.yes?("View failed examples?")
          if show_failures
            show_failure_list(result)
          end
        else
          @prompt.keypress(@color_scheme.dim("Press any key to continue..."))
        end
      end

      private

      def show_main_menu
        @prompt.select(
          "#{@color_scheme.highlight('Better RSpec Result')} - Main Menu",
          [
            { name: "View Latest Result", value: :view_latest },
            { name: "View History", value: :view_history },
            { name: @color_scheme.dim("Exit"), value: :exit }
          ]
        )
      end

      def handle_menu_choice(choice)
        case choice
        when :view_latest
          handle_view_latest
        when :view_history
          handle_view_history
        end
      end

      def show_failure_list(result)
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
