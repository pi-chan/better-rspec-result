# frozen_string_literal: true

require "tty-prompt"
require_relative "components/color_scheme"
require_relative "components/formatter"
require_relative "detail_view"
require_relative "search_filter"

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
          choice = show_main_menu(failed_examples)

          case choice
          when :search
            filtered = perform_search(failed_examples)
            show_filtered_results(filtered) if filtered && !filtered.empty?
          when :back
            break
          else
            show_failure_detail(choice)
          end
        end
      end

      def format_failure_item(example, index)
        location = @formatter.format_file_location(
          example["file_path"],
          example["line_number"]
        )

        "#{@color_scheme.failed("[#{index + 1}]")} #{example['full_description']}\n    " \
          "#{@color_scheme.dim(location)}"
      end

      def show_failure_detail(example)
        detail_view = DetailView.new(
          example: example,
          prompt: @prompt,
          color_scheme: @color_scheme,
          formatter: @formatter
        )
        detail_view.show
      end

      private

      def show_main_menu(failed_examples)
        choices = [
          { name: "🔍 Search in failures", value: :search }
        ]

        choices += failed_examples.each_with_index.map do |example, index|
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

      def perform_search(examples)
        search_filter = SearchFilter.new(
          examples: examples,
          prompt: @prompt,
          color_scheme: @color_scheme,
          formatter: @formatter
        )
        result = search_filter.show_search_ui

        # Return nil if cancelled
        return nil if result[:cancelled]

        # Show message if no results found
        if result[:results].empty?
          @prompt.say(@color_scheme.dim("No results found matching your search criteria."))
          return nil
        end

        result[:results]
      rescue StandardError
        nil
      end

      def show_filtered_results(filtered)
        loop do
          choice = show_result_menu(filtered, "Filtered Results:")
          break if choice == :back

          show_failure_detail(choice)
        end
      end

      def show_result_menu(examples, title)
        choices = examples.each_with_index.map do |example, index|
          {
            name: format_failure_item(example, index),
            value: example
          }
        end

        choices << { name: @color_scheme.dim("← Back"), value: :back }

        @prompt.select(
          title,
          choices,
          per_page: 15,
          cycle: true
        )
      end
    end
  end
end
