# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/better_rspec_result/ui/failure_list"
require_relative "../../../lib/better_rspec_result/ui/components/color_scheme"
require_relative "../../../lib/better_rspec_result/ui/components/formatter"
require_relative "../../../lib/better_rspec_result/storage/result"

RSpec.describe BetterRspecResult::UI::FailureList do
  let(:color_scheme) { BetterRspecResult::UI::Components::ColorScheme.new }
  let(:formatter) { BetterRspecResult::UI::Components::Formatter.new }
  let(:prompt) { instance_double(TTY::Prompt) }

  let(:failed_examples) do
    [
      {
        "description" => "returns true for valid user",
        "full_description" => "User validations returns true for valid user",
        "file_path" => "spec/models/user_spec.rb",
        "line_number" => 15,
        "status" => "failed",
        "exception" => {
          "class" => "RSpec::Expectations::ExpectationNotMetError",
          "message" => "expected true, got false"
        }
      },
      {
        "description" => "login with invalid credentials",
        "full_description" => "Authentication login with invalid credentials",
        "file_path" => "spec/services/auth_spec.rb",
        "line_number" => 42,
        "status" => "failed",
        "exception" => {
          "class" => "RSpec::Expectations::ExpectationNotMetError",
          "message" => "expected nil to be present"
        }
      }
    ]
  end

  let(:result_data) do
    {
      "summary" => {
        "example_count" => 50,
        "failure_count" => 2,
        "pending_count" => 0,
        "duration" => 2.5
      },
      "examples" => failed_examples + [
        {
          "description" => "passing test",
          "status" => "passed"
        }
      ],
      "metadata" => {
        "timestamp" => "2026-01-26T14:30:00+09:00",
        "ruby_version" => "3.2.0",
        "rspec_version" => "3.12.0",
        "working_directory" => "/test"
      }
    }
  end

  let(:result) { BetterRspecResult::Storage::Result.new(result_data) }
  let(:failure_list) do
    described_class.new(
      result: result,
      prompt: prompt,
      color_scheme: color_scheme,
      formatter: formatter
    )
  end

  describe "#initialize" do
    it "requires result parameter" do
      expect do
        described_class.new(
          result: result,
          prompt: prompt,
          color_scheme: color_scheme,
          formatter: formatter
        )
      end.not_to raise_error
    end

    it "uses default color_scheme if not provided" do
      list = described_class.new(result: result, prompt: prompt)
      expect(list.instance_variable_get(:@color_scheme)).to be_a(BetterRspecResult::UI::Components::ColorScheme)
    end

    it "uses default formatter if not provided" do
      list = described_class.new(result: result, prompt: prompt)
      expect(list.instance_variable_get(:@formatter)).to be_a(BetterRspecResult::UI::Components::Formatter)
    end
  end

  describe "#format_failure_item" do
    it "formats failure with index and description" do
      example = failed_examples.first
      formatted = failure_list.format_failure_item(example, 0)

      expect(formatted).to include("[1]")
      expect(formatted).to include("User validations returns true for valid user")
      expect(formatted).to include("spec/models/user_spec.rb:15")
    end

    it "handles multiple failures" do
      formatted1 = failure_list.format_failure_item(failed_examples[0], 0)
      formatted2 = failure_list.format_failure_item(failed_examples[1], 1)

      expect(formatted1).to include("[1]")
      expect(formatted2).to include("[2]")
    end
  end

  describe "#show_failure_detail" do
    it "displays failure details using DetailView" do
      example = failed_examples.first

      allow(prompt).to receive(:say)
      allow(prompt).to receive(:select).and_return(:back)

      failure_list.show_failure_detail(example)

      expect(prompt).to have_received(:say).at_least(:once)
      expect(prompt).to have_received(:select).with("Actions:", kind_of(Array), anything)
    end
  end

  describe "#show" do
    context "when there are failures" do
      it "displays failure selection menu" do
        expect(prompt).to receive(:select).with(
          "Select a failed example to view details:",
          kind_of(Array),
          hash_including(per_page: 15, cycle: true)
        ).and_return(:back)

        failure_list.show
      end

      it "returns when back is selected" do
        allow(prompt).to receive(:select).and_return(:back)

        expect { failure_list.show }.not_to raise_error
      end

      it "shows detail when a failure is selected" do
        allow(prompt).to receive(:select).and_return(
          failed_examples.first,
          :back,
          :back
        )
        allow(prompt).to receive(:say)

        failure_list.show

        expect(prompt).to have_received(:say).at_least(:once)
        expect(prompt).to have_received(:select).at_least(:twice)
      end
    end

    context "when result has no failures" do
      let(:passing_result_data) do
        {
          "summary" => {
            "example_count" => 10,
            "failure_count" => 0,
            "pending_count" => 0,
            "duration" => 1.0
          },
          "examples" => [
            { "description" => "test", "status" => "passed" }
          ],
          "metadata" => {
            "timestamp" => "2026-01-26T14:30:00+09:00",
            "ruby_version" => "3.2.0",
            "rspec_version" => "3.12.0",
            "working_directory" => "/test"
          }
        }
      end

      let(:passing_result) { BetterRspecResult::Storage::Result.new(passing_result_data) }
      let(:empty_failure_list) do
        described_class.new(
          result: passing_result,
          prompt: prompt,
          color_scheme: color_scheme,
          formatter: formatter
        )
      end

      it "shows no failures message" do
        expect(prompt).to receive(:say).with(/No failed examples/)
        empty_failure_list.show
      end
    end

    context "with search functionality" do
      it "displays search option in menu" do
        allow(prompt).to receive(:select).and_return(:back)

        failure_list.show

        expect(prompt).to have_received(:select).with(
          "Select a failed example to view details:",
          array_including(hash_including(value: :search)),
          hash_including(per_page: 15, cycle: true)
        )
      end

      it "performs search and displays filtered results" do
        allow(prompt).to receive(:select).and_return(:search, :back)
        allow(prompt).to receive(:ask).with("Enter search query:", required: false).and_return("auth")
        allow(prompt).to receive(:multi_select).and_return(%i[description file_path])
        allow(prompt).to receive(:say)

        failure_list.show

        # Verify search was triggered
        expect(prompt).to have_received(:ask).with("Enter search query:", required: false)
        expect(prompt).to have_received(:multi_select)
      end

      it "shows message when no results found" do
        allow(prompt).to receive(:select).and_return(:search, :back)
        allow(prompt).to receive(:ask).with("Enter search query:", required: false).and_return("nonexistent")
        allow(prompt).to receive(:multi_select).and_return([:description])
        allow(prompt).to receive(:say)

        failure_list.show

        expect(prompt).to have_received(:say).with(
          color_scheme.dim("No results found matching your search criteria.")
        )
      end

      it "handles cancelled search" do
        allow(prompt).to receive(:select).and_return(:search, :back)
        allow(prompt).to receive(:ask).with("Enter search query:", required: false).and_return(nil)

        expect { failure_list.show }.not_to raise_error
      end

      it "allows viewing details of filtered results" do
        allow(prompt).to receive(:select).and_return(
          :search,                    # Select search
          failed_examples.first,      # Select a filtered result
          :back,                      # Back from detail view
          :back                       # Back from filtered menu
        )
        allow(prompt).to receive(:ask).with("Enter search query:", required: false).and_return("user")
        allow(prompt).to receive(:multi_select).and_return([:description])
        allow(prompt).to receive(:say)

        failure_list.show

        # Verify detail view was shown for the selected result
        expect(prompt).to have_received(:say).at_least(:once)
      end
    end
  end
end
