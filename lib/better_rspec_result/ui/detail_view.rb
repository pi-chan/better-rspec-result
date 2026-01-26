# frozen_string_literal: true

require "tty-prompt"
require "tty-box"
require_relative "components/color_scheme"
require_relative "components/formatter"
require_relative "clipboard"

module BetterRspecResult
  module UI
    # Displays detailed view of a failed example
    class DetailView
      PROJECT_DIRECTORIES = %w[spec/ lib/ app/].freeze

      def initialize(example:, prompt:, color_scheme: nil, formatter: nil, clipboard: nil)
        @example = example
        @prompt = prompt
        @color_scheme = color_scheme || Components::ColorScheme.new
        @formatter = formatter || Components::Formatter.new
        @clipboard = clipboard || Clipboard.new
      end

      def show
        display_detail_box
        show_action_menu
      end

      def format_detail_box
        lines = []
        lines << @color_scheme.highlight(@example["full_description"])
        lines << ""

        location = @formatter.format_file_location(
          @example["file_path"],
          @example["line_number"]
        )
        lines << "Location: #{@color_scheme.dim(location)}"
        lines << ""

        if @example["exception"]
          lines << "Error Class: #{@color_scheme.failed(@example["exception"]["class"])}"
          lines << ""
          lines << "Message:"
          lines << "  #{@example["exception"]["message"]}"
          lines << ""

          if @example["exception"]["backtrace"]
            lines << "Backtrace (first 5 lines):"
            backtrace_preview = @example["exception"]["backtrace"].take(5)
            highlighted = highlight_project_files(backtrace_preview)
            highlighted.each do |line|
              lines << "  #{line}"
            end

            if @example["exception"]["backtrace"].length > 5
              remaining = @example["exception"]["backtrace"].length - 5
              lines << @color_scheme.dim("  ... and #{remaining} more lines (use 'View Full Backtrace')")
            end
          end
        end

        lines.join("\n")
      end

      def show_full_backtrace
        return unless @example["exception"] && @example["exception"]["backtrace"]

        lines = []
        lines << @color_scheme.highlight("Full Backtrace:")
        lines << ""

        highlighted = highlight_project_files(@example["exception"]["backtrace"])
        lines.concat(highlighted)

        @prompt.say(lines.join("\n"))
        @prompt.say("")
        @prompt.say(@color_scheme.dim("Press any key to continue..."))
        @prompt.keypress
      end

      def highlight_project_files(backtrace)
        backtrace.map do |line|
          if PROJECT_DIRECTORIES.any? { |dir| line.start_with?(dir) }
            @color_scheme.highlight(line)
          else
            @color_scheme.dim(line)
          end
        end
      end

      private

      def display_detail_box
        box_content = format_detail_box
        box = TTY::Box.frame(
          box_content,
          padding: 1,
          border: :thick,
          style: {
            border: {
              fg: :red
            }
          }
        )
        @prompt.say(box)
      end

      def show_action_menu
        loop do
          action = @prompt.select(
            "Actions:",
            [
              { name: "Copy Line Number", value: :copy_line },
              { name: "Copy Full Location", value: :copy_full },
              { name: "View Full Backtrace", value: :view_backtrace },
              { name: @color_scheme.dim("← Back"), value: :back }
            ],
            per_page: 10
          )

          case action
          when :copy_line
            handle_copy_line_number
          when :copy_full
            handle_copy_full_location
          when :view_backtrace
            show_full_backtrace
          when :back
            break
          end
        end
      end

      def handle_copy_line_number
        result = @clipboard.copy_location(
          @example["file_path"],
          @example["line_number"],
          full_path: false
        )

        display_copy_result(result)
      end

      def handle_copy_full_location
        result = @clipboard.copy_location(
          @example["file_path"],
          @example["line_number"],
          full_path: true
        )

        display_copy_result(result)
      end

      def display_copy_result(result)
        if result[:success]
          if result[:method] == :clipboard
            @prompt.say(@color_scheme.passed("✓ Copied to clipboard"))
          else
            @prompt.say(@color_scheme.pending("⚠ Clipboard unavailable, saved to: #{result[:file_path]}"))
          end
        else
          message = result[:message] || "Unknown error"
          @prompt.say(@color_scheme.failed("✗ Failed to copy: #{message}"))
        end
      end
    end
  end
end
