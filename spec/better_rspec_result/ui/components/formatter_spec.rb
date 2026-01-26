# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../lib/better_rspec_result/ui/components/formatter"

RSpec.describe BetterRspecResult::UI::Components::Formatter do
  let(:formatter) { described_class.new }

  describe "#format_timestamp" do
    it "formats ISO8601 timestamp to human-readable format" do
      timestamp = "2026-01-26T14:30:45+09:00"
      result = formatter.format_timestamp(timestamp)
      expect(result).to eq("2026-01-26 14:30:45")
    end

    it "handles different timezones" do
      timestamp = "2026-01-26T05:30:45Z"
      result = formatter.format_timestamp(timestamp)
      expect(result).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
    end

    it "returns original string if parsing fails" do
      invalid_timestamp = "invalid"
      result = formatter.format_timestamp(invalid_timestamp)
      expect(result).to eq("invalid")
    end
  end

  describe "#format_duration" do
    it "formats duration in seconds with one decimal place" do
      expect(formatter.format_duration(2.5)).to eq("2.5s")
    end

    it "formats whole numbers without unnecessary decimals" do
      expect(formatter.format_duration(3.0)).to eq("3.0s")
    end

    it "formats very small durations" do
      expect(formatter.format_duration(0.123)).to eq("0.1s")
    end

    it "handles zero duration" do
      expect(formatter.format_duration(0.0)).to eq("0.0s")
    end
  end

  describe "#format_file_location" do
    it "combines file path and line number" do
      result = formatter.format_file_location("spec/models/user_spec.rb", 15)
      expect(result).to eq("spec/models/user_spec.rb:15")
    end

    it "handles absolute paths" do
      result = formatter.format_file_location("/Users/test/project/spec/user_spec.rb", 42)
      expect(result).to eq("/Users/test/project/spec/user_spec.rb:42")
    end

    it "handles nil line number" do
      result = formatter.format_file_location("spec/user_spec.rb", nil)
      expect(result).to eq("spec/user_spec.rb")
    end
  end

  describe "#truncate" do
    it "returns original text if shorter than length" do
      text = "short text"
      result = formatter.truncate(text, 20)
      expect(result).to eq("short text")
    end

    it "truncates long text and adds ellipsis" do
      text = "This is a very long text that should be truncated"
      result = formatter.truncate(text, 20)
      expect(result).to eq("This is a very lo...")
      expect(result.length).to eq(20)
    end

    it "handles exact length match" do
      text = "exactly twenty chars"
      result = formatter.truncate(text, 20)
      expect(result).to eq("exactly twenty chars")
    end

    it "handles empty string" do
      result = formatter.truncate("", 10)
      expect(result).to eq("")
    end

    it "handles very small length" do
      text = "hello world"
      result = formatter.truncate(text, 5)
      expect(result).to eq("he...")
    end
  end

  describe "#format_status" do
    it "returns 'PASSED' for successful result" do
      result_mock = double(success?: true)
      expect(formatter.format_status(result_mock)).to eq("PASSED")
    end

    it "returns 'FAILED' for failed result" do
      result_mock = double(success?: false)
      expect(formatter.format_status(result_mock)).to eq("FAILED")
    end
  end

  describe "integration" do
    it "can be instantiated without arguments" do
      expect { described_class.new }.not_to raise_error
    end

    it "all methods return strings" do
      timestamp = formatter.format_timestamp("2026-01-26T14:30:45+09:00")
      duration = formatter.format_duration(2.5)
      location = formatter.format_file_location("spec/test.rb", 10)
      truncated = formatter.truncate("test", 10)
      status = formatter.format_status(double(success?: true))

      expect(timestamp).to be_a(String)
      expect(duration).to be_a(String)
      expect(location).to be_a(String)
      expect(truncated).to be_a(String)
      expect(status).to be_a(String)
    end
  end
end
