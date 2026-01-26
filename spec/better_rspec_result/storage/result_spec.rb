# frozen_string_literal: true

require "spec_helper"
require "better_rspec_result/storage/result"

RSpec.describe BetterRspecResult::Storage::Result do
  let(:sample_data) do
    {
      "metadata" => {
        "version" => "0.1.0",
        "timestamp" => "2026-01-26T14:30:15+09:00",
        "command" => "bundle exec rspec",
        "seed" => 12_345,
        "rspec_version" => "3.13.0",
        "ruby_version" => "3.3.0",
        "working_directory" => "/path/to/project"
      },
      "summary" => {
        "duration" => 2.5,
        "example_count" => 50,
        "failure_count" => 5,
        "pending_count" => 2,
        "errors_outside_of_examples_count" => 0
      },
      "examples" => [
        {
          "id" => "./spec/models/user_spec.rb[1:1:1]",
          "description" => "returns true for valid user",
          "full_description" => "User validations returns true for valid user",
          "status" => "passed",
          "file_path" => "spec/models/user_spec.rb",
          "line_number" => 15,
          "run_time" => 0.05
        },
        {
          "id" => "./spec/models/user_spec.rb[1:1:2]",
          "description" => "returns false for invalid user",
          "full_description" => "User validations returns false for invalid user",
          "status" => "failed",
          "file_path" => "spec/models/user_spec.rb",
          "line_number" => 20,
          "run_time" => 0.03,
          "exception" => {
            "class" => "RSpec::Expectations::ExpectationNotMetError",
            "message" => "expected true, got false",
            "backtrace" => ["spec/models/user_spec.rb:21:in `block (3 levels) in <top>'"]
          }
        },
        {
          "id" => "./spec/models/user_spec.rb[1:1:3]",
          "description" => "pending example",
          "full_description" => "User validations pending example",
          "status" => "pending",
          "file_path" => "spec/models/user_spec.rb",
          "line_number" => 25,
          "run_time" => 0.0
        }
      ]
    }
  end

  subject(:result) { described_class.new(sample_data) }

  describe "#initialize" do
    it "sets metadata" do
      expect(result.metadata).to eq(sample_data["metadata"])
    end

    it "sets summary" do
      expect(result.summary).to eq(sample_data["summary"])
    end

    it "sets examples" do
      expect(result.examples).to eq(sample_data["examples"])
    end

    context "with empty data" do
      subject(:result) { described_class.new({}) }

      it "initializes with empty hashes" do
        expect(result.metadata).to eq({})
        expect(result.summary).to eq({})
        expect(result.examples).to eq([])
      end
    end
  end

  describe "#failed_examples" do
    it "returns only failed examples" do
      expect(result.failed_examples.size).to eq(1)
      expect(result.failed_examples.first["status"]).to eq("failed")
    end
  end

  describe "#passed_examples" do
    it "returns only passed examples" do
      expect(result.passed_examples.size).to eq(1)
      expect(result.passed_examples.first["status"]).to eq("passed")
    end
  end

  describe "#pending_examples" do
    it "returns only pending examples" do
      expect(result.pending_examples.size).to eq(1)
      expect(result.pending_examples.first["status"]).to eq("pending")
    end
  end

  describe "#success_rate" do
    it "calculates success rate as percentage" do
      # 50 total, 5 failed, 2 pending = 43 passed
      # (43 / 50) * 100 = 86.0%
      expect(result.success_rate).to eq(86.0)
    end

    context "with no examples" do
      subject(:result) { described_class.new("summary" => { "example_count" => 0 }) }

      it "returns 0.0" do
        expect(result.success_rate).to eq(0.0)
      end
    end
  end

  describe "#example_count" do
    it "returns total example count from summary" do
      expect(result.example_count).to eq(50)
    end

    context "when summary is empty" do
      subject(:result) { described_class.new("examples" => [1, 2, 3]) }

      it "falls back to examples array size" do
        expect(result.example_count).to eq(3)
      end
    end
  end

  describe "#failure_count" do
    it "returns failure count from summary" do
      expect(result.failure_count).to eq(5)
    end

    context "when summary is empty" do
      subject(:result) { described_class.new(sample_data.merge("summary" => {})) }

      it "falls back to counting failed examples" do
        expect(result.failure_count).to eq(1)
      end
    end
  end

  describe "#passed_count" do
    it "calculates passed count" do
      # 50 total - 5 failed - 2 pending = 43 passed
      expect(result.passed_count).to eq(43)
    end
  end

  describe "#pending_count" do
    it "returns pending count from summary" do
      expect(result.pending_count).to eq(2)
    end
  end

  describe "#duration" do
    it "returns duration from summary" do
      expect(result.duration).to eq(2.5)
    end

    context "when summary is empty" do
      subject(:result) { described_class.new({}) }

      it "returns 0.0" do
        expect(result.duration).to eq(0.0)
      end
    end
  end

  describe "#timestamp" do
    it "returns timestamp from metadata" do
      expect(result.timestamp).to eq("2026-01-26T14:30:15+09:00")
    end
  end

  describe "#to_h" do
    it "converts to hash" do
      hash = result.to_h
      expect(hash).to include("metadata", "summary", "examples")
      expect(hash["metadata"]).to eq(sample_data["metadata"])
    end
  end

  describe "#to_json" do
    it "converts to JSON string" do
      json = result.to_json
      expect(json).to be_a(String)
      parsed = JSON.parse(json)
      expect(parsed).to include("metadata", "summary", "examples")
    end
  end

  describe "#success?" do
    it "returns true when no failures" do
      success_data = sample_data.merge("summary" => { "failure_count" => 0 })
      success_result = described_class.new(success_data)
      expect(success_result.success?).to be true
    end

    it "returns false when there are failures" do
      expect(result.success?).to be false
    end
  end

  describe "#failed?" do
    it "returns true when there are failures" do
      expect(result.failed?).to be true
    end

    it "returns false when no failures" do
      success_data = sample_data.merge("summary" => { "failure_count" => 0 })
      success_result = described_class.new(success_data)
      expect(success_result.failed?).to be false
    end
  end
end
