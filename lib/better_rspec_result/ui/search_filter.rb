# frozen_string_literal: true

require "tty-prompt"

module BetterRspecResult
  module UI
    # Provides search and filtering capabilities for test examples
    class SearchFilter
      def initialize(examples:, prompt:, color_scheme:, formatter:)
        @examples = examples
        @prompt = prompt
        @color_scheme = color_scheme
        @formatter = formatter
      end

      # Shows search UI and returns result hash
      # Returns: { cancelled: false, results: [...] } or { cancelled: true }
      def show_search_ui
        query = search_query
        return { cancelled: true } if query.nil? || query.empty?

        fields = select_search_fields
        results = filter_examples(query, fields)
        { cancelled: false, results: results }
      end

      private

      def search_query
        @prompt.ask("Enter search query:", required: false)
      end

      def select_search_fields
        @prompt.multi_select(
          "Select fields to search:",
          [
            { name: "Description", value: :description },
            { name: "File Path", value: :file_path },
            { name: "Error Message", value: :error_message }
          ],
          default: [1, 2, 3]
        )
      end

      def filter_examples(query, fields)
        @examples.select do |example|
          match_any_field?(example, query, fields)
        end
      end

      def match_any_field?(example, query, fields)
        fields.any? { |field| field_matches?(example, field, query) }
      end

      def field_matches?(example, field, query)
        value = extract_field_value(example, field)
        return false if value.nil?

        value.downcase.include?(query.downcase)
      end

      def extract_field_value(example, field)
        case field
        when :description
          [example["description"], example["full_description"]].compact.join(" ")
        when :file_path
          example["file_path"]
        when :error_message
          example.dig("exception", "message")
        end
      end
    end
  end
end
