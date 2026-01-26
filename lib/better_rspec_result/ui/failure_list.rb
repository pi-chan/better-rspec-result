# frozen_string_literal: true

require "tty-prompt"
require_relative "components/color_scheme"
require_relative "components/formatter"

module BetterRspecResult
  module UI
    # Displays interactive list of failed examples
    class FailureList
      def initialize(result:, prompt:, color_scheme: nil, formatter: nil)
        @result = result
        @prompt = prompt
        @color_scheme = color_scheme || Components::ColorScheme.new
        @formatter = formatter || Components::Formatter.new
      end

      def show
        failed_examples = @result.failed_examples

        if failed_examples.empty?
          @prompt.say(@color_scheme.dim("No failed examples to display."))
          return
        end

        loop do
          choice = show_failure_menu(failed_examples)
          break if choice == :back

          show_failure_detail(choice)
        end
      end

      def format_failure_item(example, index)
        location = @formatter.format_file_location(
          example["file_path"],
          example["line_number"]
        )

        "#{@color_scheme.failed("[#{index + 1}]")} #{example["full_description"]}\n" \
        "    #{@color_scheme.dim(location)}"
      end

      def show_failure_detail(example)
        details = []
        details << ""
        details << @color_scheme.failed("=" * 80)
        details << @color_scheme.highlight(example["full_description"])
        details << @color_scheme.failed("=" * 80)
        details << ""

        location = @formatter.format_file_location(
          example["file_path"],
          example["line_number"]
        )
        details << "Location: #{@color_scheme.dim(location)}"
        details << ""

        if example["exception"]
          details << "Error Class: #{@color_scheme.failed(example["exception"]["class"])}"
          details << "Message: #{example["exception"]["message"]}"
          details << ""
        end

        details << @color_scheme.dim("Press any key to continue...")

        @prompt.say(details.join("\n"))
        @prompt.keypress
      end

      private

      def show_failure_menu(failed_examples)
        choices = failed_examples.each_with_index.map do |example, index|
          {
            name: format_failure_item(example, index),
            value: example
          }
        end

        choices << { name: @color_scheme.dim("← Back"), value: :back }

        @prompt.select(
          "Select a failed example to view details:",
          choices,
          per_page: 15,
          cycle: true
        )
      end
    end
  end
end
