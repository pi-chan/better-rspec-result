# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/better_rspec_result/ui/search_filter"
require_relative "../../../lib/better_rspec_result/ui/components/color_scheme"
require_relative "../../../lib/better_rspec_result/ui/components/formatter"

RSpec.describe BetterRspecResult::UI::SearchFilter do
  let(:prompt) { instance_double(TTY::Prompt) }
  let(:color_scheme) { BetterRspecResult::UI::Components::ColorScheme.new }
  let(:formatter) { BetterRspecResult::UI::Components::Formatter.new }

  let(:examples) do
    [
      {
        "description" => "returns true",
        "full_description" => "User validations returns true",
        "file_path" => "spec/models/user_spec.rb",
        "status" => "failed",
        "exception" => { "message" => "expected true, got false" }
      },
      {
        "description" => "saves record",
        "full_description" => "User#save saves record",
        "file_path" => "spec/models/post_spec.rb",
        "status" => "failed",
        "exception" => { "message" => "validation failed" }
      },
      {
        "description" => "updates timestamp",
        "full_description" => "User#touch updates timestamp",
        "file_path" => "spec/models/user_spec.rb",
        "status" => "passed"
      }
    ]
  end

  subject(:search_filter) do
    described_class.new(
      examples: examples,
      prompt: prompt,
      color_scheme: color_scheme,
      formatter: formatter
    )
  end

  describe "#show_search_ui" do
    context "when user enters a query and selects fields" do
      before do
        allow(prompt).to receive(:ask).with("Enter search query:", required: false).and_return(query)
        allow(prompt).to receive(:multi_select).and_return(selected_fields)
      end

      context "with description search" do
        let(:query) { "returns" }
        let(:selected_fields) { [:description] }

        it "returns matching examples by description" do
          result = search_filter.show_search_ui
          expect(result[:cancelled]).to be false
          expect(result[:results].size).to eq(1)
          expect(result[:results].first["description"]).to eq("returns true")
        end
      end

      context "with full_description search" do
        let(:query) { "User#save" }
        let(:selected_fields) { [:description] }

        it "returns matching examples by full_description" do
          result = search_filter.show_search_ui
          expect(result[:cancelled]).to be false
          expect(result[:results].size).to eq(1)
          expect(result[:results].first["description"]).to eq("saves record")
        end
      end

      context "with file_path search" do
        let(:query) { "user_spec" }
        let(:selected_fields) { [:file_path] }

        it "returns matching examples by file path" do
          result = search_filter.show_search_ui
          expect(result[:cancelled]).to be false
          expect(result[:results].size).to eq(2)
          expect(result[:results].map { |r| r["file_path"] }.uniq).to eq(["spec/models/user_spec.rb"])
        end
      end

      context "with error_message search" do
        let(:query) { "expected" }
        let(:selected_fields) { [:error_message] }

        it "returns matching examples by error message" do
          result = search_filter.show_search_ui
          expect(result[:cancelled]).to be false
          expect(result[:results].size).to eq(1)
          expect(result[:results].first["exception"]["message"]).to include("expected")
        end
      end

      context "with multiple fields selected" do
        let(:query) { "post" }
        let(:selected_fields) { %i[description file_path] }

        it "returns examples matching any of the selected fields" do
          result = search_filter.show_search_ui
          expect(result[:cancelled]).to be false
          expect(result[:results].size).to eq(1)
          expect(result[:results].first["file_path"]).to include("post_spec")
        end
      end

      context "with case insensitive search" do
        let(:query) { "USER" }
        let(:selected_fields) { [:file_path] }

        it "matches regardless of case" do
          result = search_filter.show_search_ui
          expect(result[:cancelled]).to be false
          expect(result[:results].size).to eq(2)
        end
      end

      context "when no matches are found" do
        let(:query) { "nonexistent" }
        let(:selected_fields) { %i[description file_path error_message] }

        it "returns an empty results array" do
          result = search_filter.show_search_ui
          expect(result[:cancelled]).to be false
          expect(result[:results]).to be_empty
        end
      end
    end

    context "when user cancels query input" do
      before do
        allow(prompt).to receive(:ask).with("Enter search query:", required: false).and_return(nil)
      end

      it "returns cancelled status" do
        result = search_filter.show_search_ui
        expect(result[:cancelled]).to be true
      end
    end

    context "when user enters empty query" do
      before do
        allow(prompt).to receive(:ask).with("Enter search query:", required: false).and_return("")
      end

      it "returns cancelled status" do
        result = search_filter.show_search_ui
        expect(result[:cancelled]).to be true
      end
    end

    context "when example has no exception" do
      let(:query) { "timestamp" }
      let(:selected_fields) { [:error_message] }

      before do
        allow(prompt).to receive(:ask).with("Enter search query:", required: false).and_return(query)
        allow(prompt).to receive(:multi_select).and_return(selected_fields)
      end

      it "does not crash and returns no matches" do
        result = search_filter.show_search_ui
        expect(result[:cancelled]).to be false
        expect(result[:results]).to be_empty
      end
    end
  end
end
