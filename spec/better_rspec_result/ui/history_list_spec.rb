# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require_relative "../../../lib/better_rspec_result/ui/history_list"
require_relative "../../../lib/better_rspec_result/ui/components/color_scheme"
require_relative "../../../lib/better_rspec_result/ui/components/formatter"
require_relative "../../../lib/better_rspec_result/storage/json_storage"
require_relative "../../../lib/better_rspec_result/storage/result"

RSpec.describe BetterRspecResult::UI::HistoryList do
  let(:temp_dir) { Dir.mktmpdir("brr-test") }
  let(:storage) { BetterRspecResult::Storage::JsonStorage.new(temp_dir) }
  let(:color_scheme) { BetterRspecResult::UI::Components::ColorScheme.new }
  let(:formatter) { BetterRspecResult::UI::Components::Formatter.new }
  let(:prompt) { instance_double(TTY::Prompt) }

  let(:result_data1) do
    {
      "summary" => {
        "example_count" => 50,
        "failure_count" => 0,
        "pending_count" => 0,
        "duration" => 2.5
      },
      "examples" => [
        { "description" => "test", "status" => "passed" }
      ],
      "metadata" => {
        "timestamp" => "2026-01-26T15:30:00+09:00",
        "ruby_version" => "3.2.0",
        "rspec_version" => "3.12.0",
        "working_directory" => "/test"
      }
    }
  end

  let(:result_data2) do
    {
      "summary" => {
        "example_count" => 50,
        "failure_count" => 5,
        "pending_count" => 0,
        "duration" => 3.1
      },
      "examples" => [
        {
          "description" => "test",
          "status" => "failed",
          "exception" => {
            "class" => "Error",
            "message" => "test error"
          }
        }
      ],
      "metadata" => {
        "timestamp" => "2026-01-26T14:00:00+09:00",
        "ruby_version" => "3.2.0",
        "rspec_version" => "3.12.0",
        "working_directory" => "/test"
      }
    }
  end

  let(:history_list) do
    described_class.new(
      storage: storage,
      prompt: prompt,
      color_scheme: color_scheme,
      formatter: formatter
    )
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#initialize" do
    it "requires storage parameter" do
      expect do
        described_class.new(
          storage: storage,
          prompt: prompt,
          color_scheme: color_scheme,
          formatter: formatter
        )
      end.not_to raise_error
    end

    it "uses default color_scheme if not provided" do
      list = described_class.new(storage: storage, prompt: prompt)
      expect(list.instance_variable_get(:@color_scheme)).to be_a(BetterRspecResult::UI::Components::ColorScheme)
    end

    it "uses default formatter if not provided" do
      list = described_class.new(storage: storage, prompt: prompt)
      expect(list.instance_variable_get(:@formatter)).to be_a(BetterRspecResult::UI::Components::Formatter)
    end
  end

  describe "#load_results" do
    before do
      result1 = BetterRspecResult::Storage::Result.new(result_data1)
      result2 = BetterRspecResult::Storage::Result.new(result_data2)

      storage.save(result1)
      storage.save(result2)
    end

    it "loads all results from storage" do
      results = history_list.load_results
      expect(results).to be_an(Array)
      expect(results.size).to eq(2)
    end

    it "returns results in reverse chronological order" do
      results = history_list.load_results
      expect(results.first.timestamp).to be > results.last.timestamp
    end
  end

  describe "#format_result_item" do
    it "formats passed result" do
      result = BetterRspecResult::Storage::Result.new(result_data1)
      formatted = history_list.format_result_item(result)

      expect(formatted).to include("PASSED")
      expect(formatted).to include("50 examples")
      expect(formatted).to include("0 failures")
      expect(formatted).to include("2.5s")
    end

    it "formats failed result" do
      result = BetterRspecResult::Storage::Result.new(result_data2)
      formatted = history_list.format_result_item(result)

      expect(formatted).to include("FAILED")
      expect(formatted).to include("50 examples")
      expect(formatted).to include("5 failures")
      expect(formatted).to include("3.1s")
    end
  end

  describe "#show" do
    context "when there are results" do
      before do
        result1 = BetterRspecResult::Storage::Result.new(result_data1)
        result2 = BetterRspecResult::Storage::Result.new(result_data2)

        storage.save(result1)
        storage.save(result2)
      end

      it "displays result selection menu" do
        expect(prompt).to receive(:select).with(
          "Select a result:",
          kind_of(Array),
          hash_including(per_page: kind_of(Integer))
        ).and_return(:back)

        history_list.show
      end

      it "returns when back is selected" do
        allow(prompt).to receive(:select).and_return(:back)

        expect { history_list.show }.not_to raise_error
      end

      it "shows detail menu when a result is selected" do
        result = BetterRspecResult::Storage::Result.new(result_data1)

        allow(prompt).to receive(:select).and_return(result, :back)

        expect(history_list).to receive(:show_result_detail_menu).with(result)

        history_list.show
      end
    end

    context "when there are no results" do
      it "shows no results message" do
        expect(prompt).to receive(:say).with(/No results found/)
        history_list.show
      end
    end
  end

  describe "#show_result_detail_menu" do
    let(:result) { BetterRspecResult::Storage::Result.new(result_data1) }

    it "displays summary for passed results" do
      allow(prompt).to receive(:say)
      allow(prompt).to receive(:keypress)

      history_list.show_result_detail_menu(result)

      expect(prompt).to have_received(:say)
      expect(prompt).to have_received(:keypress)
    end

    it "shows failures directly for failed results" do
      failed_result = BetterRspecResult::Storage::Result.new(result_data2)
      allow(prompt).to receive(:select).and_return(:back)

      history_list.show_result_detail_menu(failed_result)

      expect(prompt).to have_received(:select)
    end
  end
end
