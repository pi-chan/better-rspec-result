# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require_relative "../../../lib/better_rspec_result/ui/viewer"
require_relative "../../../lib/better_rspec_result/ui/components/color_scheme"
require_relative "../../../lib/better_rspec_result/storage/json_storage"
require_relative "../../../lib/better_rspec_result/storage/result"

RSpec.describe BetterRspecResult::UI::Viewer do
  let(:temp_dir) { Dir.mktmpdir("brr-test") }
  let(:storage) { BetterRspecResult::Storage::JsonStorage.new(temp_dir) }
  let(:color_scheme) { BetterRspecResult::UI::Components::ColorScheme.new }
  let(:prompt) { instance_double(TTY::Prompt) }

  let(:result_data) do
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

  let(:viewer) do
    described_class.new(
      storage: storage,
      prompt: prompt,
      color_scheme: color_scheme
    )
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#initialize" do
    it "requires storage parameter" do
      expect {
        described_class.new(
          storage: storage,
          prompt: prompt,
          color_scheme: color_scheme
        )
      }.not_to raise_error
    end

    it "uses default prompt if not provided" do
      expect {
        described_class.new(storage: storage)
      }.not_to raise_error
    end

    it "uses default color_scheme if not provided" do
      viewer_instance = described_class.new(storage: storage, prompt: prompt)
      expect(viewer_instance.instance_variable_get(:@color_scheme)).to be_a(BetterRspecResult::UI::Components::ColorScheme)
    end
  end

  describe "#start" do
    it "displays history list directly" do
      allow(prompt).to receive(:say)

      expect(viewer).to receive(:handle_view_history)

      viewer.start
    end

    it "handles Interrupt exception gracefully" do
      allow(viewer).to receive(:handle_view_history).and_raise(Interrupt)

      expect { viewer.start }.not_to raise_error
    end
  end

  describe "#handle_view_latest" do
    context "when there is a latest result" do
      before do
        result = BetterRspecResult::Storage::Result.new(result_data)
        storage.save(result)
      end

      it "displays result summary" do
        expect(viewer).to receive(:display_result_summary)

        viewer.handle_view_latest
      end
    end

    context "when there is no result" do
      it "shows no results message" do
        expect(prompt).to receive(:say).with(/No results found/)

        viewer.handle_view_latest
      end
    end
  end

  describe "#handle_view_history" do
    it "delegates to HistoryList" do
      history_list = instance_double(BetterRspecResult::UI::HistoryList)
      allow(BetterRspecResult::UI::HistoryList).to receive(:new).and_return(history_list)
      allow(history_list).to receive(:show)

      expect(history_list).to receive(:show)

      viewer.handle_view_history
    end
  end

  describe "#display_result_summary" do
    let(:result) { BetterRspecResult::Storage::Result.new(result_data) }

    it "displays summary information" do
      expect(prompt).to receive(:say) do |message|
        expect(message).to include("Test Result Summary")
        expect(message).to include("PASSED")
        expect(message).to include("Examples: 50")
      end

      expect(prompt).to receive(:keypress)

      viewer.display_result_summary(result)
    end

    context "when result has failures" do
      let(:failed_result_data) do
        {
          "summary" => {
            "example_count" => 50,
            "failure_count" => 5,
            "pending_count" => 0,
            "duration" => 2.5
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
            "timestamp" => "2026-01-26T15:30:00+09:00",
            "ruby_version" => "3.2.0",
            "rspec_version" => "3.12.0",
            "working_directory" => "/test"
          }
        }
      end

      let(:failed_result) { BetterRspecResult::Storage::Result.new(failed_result_data) }

      it "asks if user wants to view failures" do
        allow(prompt).to receive(:say)
        expect(prompt).to receive(:yes?).with(/View failed examples/).and_return(false)

        viewer.display_result_summary(failed_result)
      end

      it "shows failures when user confirms" do
        allow(prompt).to receive(:say)
        allow(prompt).to receive(:yes?).and_return(true)

        failure_list = instance_double(BetterRspecResult::UI::FailureList)
        allow(BetterRspecResult::UI::FailureList).to receive(:new).and_return(failure_list)
        allow(failure_list).to receive(:show)

        expect(failure_list).to receive(:show)

        viewer.display_result_summary(failed_result)
      end
    end
  end
end
