# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require_relative "../../../lib/better_rspec_result/ui/clipboard"

RSpec.describe BetterRspecResult::UI::Clipboard do
  let(:clipboard) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir("brr-test") }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#copy" do
    context "when clipboard is available" do
      it "copies text to clipboard" do
        allow(Clipboard).to receive(:copy)

        clipboard.copy("test text")

        expect(Clipboard).to have_received(:copy).with("test text")
      end

      it "returns success status" do
        allow(Clipboard).to receive(:copy)

        result = clipboard.copy("test text")

        expect(result[:success]).to be true
        expect(result[:method]).to eq(:clipboard)
      end
    end

    context "when clipboard is not available" do
      before do
        allow(Clipboard).to receive(:copy).and_raise(StandardError, "No clipboard available")
      end

      it "falls back to file write" do
        allow(FileUtils).to receive(:mkdir_p)
        allow(File).to receive(:write)

        clipboard.copy("test text")

        expect(File).to have_received(:write)
      end

      it "returns fallback status with file path" do
        allow(FileUtils).to receive(:mkdir_p)
        allow(File).to receive(:write)

        result = clipboard.copy("test text")

        expect(result[:success]).to be true
        expect(result[:method]).to eq(:file)
        expect(result[:file_path]).to be_a(String)
      end
    end
  end

  describe "#copy_failure_locations" do
    let(:failures) do
      [
        { "file_path" => "spec/models/user_spec.rb", "line_number" => 15 },
        { "file_path" => "spec/services/auth_spec.rb", "line_number" => 42 },
        { "file_path" => "spec/controllers/api_spec.rb", "line_number" => 123 }
      ]
    end

    it "formats and copies all failure locations" do
      allow(Clipboard).to receive(:copy)

      clipboard.copy_failure_locations(failures)

      expected_text = "spec/models/user_spec.rb:15\nspec/services/auth_spec.rb:42\nspec/controllers/api_spec.rb:123"
      expect(Clipboard).to have_received(:copy).with(expected_text)
    end

    it "handles empty failure list" do
      allow(Clipboard).to receive(:copy)

      result = clipboard.copy_failure_locations([])

      expect(result[:success]).to be false
      expect(result[:message]).to match(/no failures/i)
    end
  end

  describe "#copy_location" do
    it "formats and copies single location" do
      allow(Clipboard).to receive(:copy)

      clipboard.copy_location("spec/models/user_spec.rb", 15)

      expect(Clipboard).to have_received(:copy).with("spec/models/user_spec.rb:15")
    end

    it "handles full path" do
      allow(Clipboard).to receive(:copy)

      clipboard.copy_location("/full/path/to/spec/models/user_spec.rb", 15, full_path: true)

      expect(Clipboard).to have_received(:copy).with("/full/path/to/spec/models/user_spec.rb:15")
    end
  end

  describe ".fallback_file_path" do
    it "returns path in home directory" do
      path = described_class.fallback_file_path

      expect(path).to include("failed_locations.txt")
    end
  end
end
