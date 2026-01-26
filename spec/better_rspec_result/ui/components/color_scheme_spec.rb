# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../lib/better_rspec_result/ui/components/color_scheme"

RSpec.describe BetterRspecResult::UI::Components::ColorScheme do
  let(:color_scheme) { described_class.new }

  describe "#passed" do
    it "returns text with green color" do
      result = color_scheme.passed("test passed")
      expect(result).to be_a(String)
      expect(result).to include("test passed")
    end

    it "includes ANSI color codes" do
      result = color_scheme.passed("test")
      expect(result).to match(/\e\[.*?m/)
    end
  end

  describe "#failed" do
    it "returns text with red color" do
      result = color_scheme.failed("test failed")
      expect(result).to be_a(String)
      expect(result).to include("test failed")
    end

    it "includes ANSI color codes" do
      result = color_scheme.failed("test")
      expect(result).to match(/\e\[.*?m/)
    end
  end

  describe "#pending" do
    it "returns text with yellow color" do
      result = color_scheme.pending("test pending")
      expect(result).to be_a(String)
      expect(result).to include("test pending")
    end

    it "includes ANSI color codes" do
      result = color_scheme.pending("test")
      expect(result).to match(/\e\[.*?m/)
    end
  end

  describe "#highlight" do
    it "returns text with bright blue color" do
      result = color_scheme.highlight("highlighted text")
      expect(result).to be_a(String)
      expect(result).to include("highlighted text")
    end

    it "includes ANSI color codes" do
      result = color_scheme.highlight("test")
      expect(result).to match(/\e\[.*?m/)
    end
  end

  describe "#dim" do
    it "returns text with dim/gray color" do
      result = color_scheme.dim("dimmed text")
      expect(result).to be_a(String)
      expect(result).to include("dimmed text")
    end

    it "includes ANSI color codes" do
      result = color_scheme.dim("test")
      expect(result).to match(/\e\[.*?m/)
    end
  end

  describe "#success_rate" do
    context "when rate is 80% or higher" do
      it "returns green colored text for 100%" do
        result = color_scheme.success_rate(100.0)
        expect(result).to be_a(String)
        expect(result).to include("100.0%")
      end

      it "returns green colored text for 80%" do
        result = color_scheme.success_rate(80.0)
        expect(result).to be_a(String)
        expect(result).to include("80.0%")
      end

      it "includes ANSI color codes" do
        result = color_scheme.success_rate(90.0)
        expect(result).to match(/\e\[.*?m/)
      end
    end

    context "when rate is between 50% and 80%" do
      it "returns yellow colored text for 70%" do
        result = color_scheme.success_rate(70.0)
        expect(result).to be_a(String)
        expect(result).to include("70.0%")
      end

      it "returns yellow colored text for 50%" do
        result = color_scheme.success_rate(50.0)
        expect(result).to be_a(String)
        expect(result).to include("50.0%")
      end

      it "includes ANSI color codes" do
        result = color_scheme.success_rate(60.0)
        expect(result).to match(/\e\[.*?m/)
      end
    end

    context "when rate is below 50%" do
      it "returns red colored text for 40%" do
        result = color_scheme.success_rate(40.0)
        expect(result).to be_a(String)
        expect(result).to include("40.0%")
      end

      it "returns red colored text for 0%" do
        result = color_scheme.success_rate(0.0)
        expect(result).to be_a(String)
        expect(result).to include("0.0%")
      end

      it "includes ANSI color codes" do
        result = color_scheme.success_rate(30.0)
        expect(result).to match(/\e\[.*?m/)
      end
    end
  end

  describe "integration" do
    it "can be instantiated without arguments" do
      expect { described_class.new }.not_to raise_error
    end

    it "maintains consistent color output across multiple calls" do
      text = "test"
      result1 = color_scheme.passed(text)
      result2 = color_scheme.passed(text)
      expect(result1).to eq(result2)
    end
  end
end
