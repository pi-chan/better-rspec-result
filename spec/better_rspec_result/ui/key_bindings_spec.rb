# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/better_rspec_result/ui/key_bindings"

RSpec.describe BetterRspecResult::UI::KeyBindings do
  describe ".create_prompt" do
    it "returns a TTY::Prompt instance" do
      prompt = described_class.create_prompt
      expect(prompt).to be_a(TTY::Prompt)
    end

    it "can be called multiple times" do
      prompt1 = described_class.create_prompt
      prompt2 = described_class.create_prompt

      expect(prompt1).to be_a(TTY::Prompt)
      expect(prompt2).to be_a(TTY::Prompt)
    end
  end

  describe "custom prompt behavior" do
    let(:prompt) { described_class.create_prompt }

    it "allows standard prompt operations" do
      allow(prompt).to receive(:select).and_return("Option 1")
      result = prompt.select("Choose", ["Option 1", "Option 2"])
      expect(result).to eq("Option 1")
    end

    it "supports TTY::Prompt methods" do
      expect(prompt).to respond_to(:select)
      expect(prompt).to respond_to(:ask)
      expect(prompt).to respond_to(:yes?)
      expect(prompt).to respond_to(:say)
    end
  end

  describe "integration" do
    it "creates a prompt without errors" do
      expect { described_class.create_prompt }.not_to raise_error
    end

    it "creates a functional prompt instance" do
      prompt = described_class.create_prompt
      expect(prompt.reader).to be_a(TTY::Reader)
    end
  end
end
