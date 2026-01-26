# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/better_rspec_result/ui/detail_view"
require_relative "../../../lib/better_rspec_result/ui/components/color_scheme"
require_relative "../../../lib/better_rspec_result/ui/components/formatter"
require_relative "../../../lib/better_rspec_result/ui/clipboard"

RSpec.describe BetterRspecResult::UI::DetailView do
  let(:color_scheme) { BetterRspecResult::UI::Components::ColorScheme.new }
  let(:formatter) { BetterRspecResult::UI::Components::Formatter.new }
  let(:clipboard) { instance_double(BetterRspecResult::UI::Clipboard) }
  let(:prompt) { instance_double(TTY::Prompt) }

  let(:example) do
    {
      "description" => "returns true for valid user",
      "full_description" => "User validations returns true for valid user",
      "file_path" => "spec/models/user_spec.rb",
      "line_number" => 15,
      "status" => "failed",
      "exception" => {
        "class" => "RSpec::Expectations::ExpectationNotMetError",
        "message" => "expected true, got false",
        "backtrace" => [
          "spec/models/user_spec.rb:21:in `block (3 levels) in <top (required)>'",
          "/path/to/rspec-core/lib/rspec/core/example.rb:123:in `run'",
          "/path/to/rspec-core/lib/rspec/core/runner.rb:45:in `run_specs'"
        ]
      }
    }
  end

  let(:detail_view) do
    described_class.new(
      example: example,
      prompt: prompt,
      color_scheme: color_scheme,
      formatter: formatter,
      clipboard: clipboard
    )
  end

  describe "#initialize" do
    it "requires example parameter" do
      expect do
        described_class.new(
          example: example,
          prompt: prompt
        )
      end.not_to raise_error
    end

    it "uses default color_scheme if not provided" do
      view = described_class.new(example: example, prompt: prompt, clipboard: clipboard)
      expect(view.instance_variable_get(:@color_scheme)).to be_a(BetterRspecResult::UI::Components::ColorScheme)
    end

    it "uses default formatter if not provided" do
      view = described_class.new(example: example, prompt: prompt, clipboard: clipboard)
      expect(view.instance_variable_get(:@formatter)).to be_a(BetterRspecResult::UI::Components::Formatter)
    end

    it "uses default clipboard if not provided" do
      view = described_class.new(example: example, prompt: prompt)
      expect(view.instance_variable_get(:@clipboard)).to be_a(BetterRspecResult::UI::Clipboard)
    end
  end

  describe "#show" do
    it "displays detail box and action menu" do
      allow(prompt).to receive(:say)
      allow(prompt).to receive(:select).and_return(:back)

      detail_view.show

      expect(prompt).to have_received(:select).with("Actions:", kind_of(Array), anything)
    end

    it "handles copy line number action" do
      allow(prompt).to receive(:select).and_return(:copy_line, :back)
      allow(clipboard).to receive(:copy_location).and_return({ success: true, method: :clipboard })
      allow(prompt).to receive(:say)

      expect(clipboard).to receive(:copy_location).with("spec/models/user_spec.rb", 15, full_path: false)

      detail_view.show
    end

    it "handles copy full location action" do
      allow(prompt).to receive(:select).and_return(:copy_full, :back)
      allow(clipboard).to receive(:copy_location).and_return({ success: true, method: :clipboard })
      allow(prompt).to receive(:say)

      expect(clipboard).to receive(:copy_location).with("spec/models/user_spec.rb", 15, full_path: true)

      detail_view.show
    end

    it "handles view full backtrace action" do
      allow(prompt).to receive(:say)
      allow(prompt).to receive(:keypress)
      allow(prompt).to receive(:select).and_return(:view_backtrace, :back)

      expect(detail_view).to receive(:show_full_backtrace).and_call_original

      detail_view.show
    end
  end

  describe "#format_detail_box" do
    it "includes error class and message" do
      box_content = detail_view.format_detail_box

      expect(box_content).to include("RSpec::Expectations::ExpectationNotMetError")
      expect(box_content).to include("expected true, got false")
    end

    it "includes file location" do
      box_content = detail_view.format_detail_box

      expect(box_content).to include("spec/models/user_spec.rb:15")
    end

    it "includes backtrace preview" do
      box_content = detail_view.format_detail_box

      expect(box_content).to include("spec/models/user_spec.rb:21")
    end
  end

  describe "#show_full_backtrace" do
    it "displays full backtrace with pager" do
      allow(prompt).to receive(:say)
      allow(prompt).to receive(:keypress)

      detail_view.show_full_backtrace

      expect(prompt).to have_received(:say).at_least(:once)
    end
  end

  describe "#highlight_project_files" do
    it "highlights project files in backtrace" do
      backtrace = [
        "spec/models/user_spec.rb:21",
        "/path/to/gem/rspec-core/lib/rspec.rb:123"
      ]

      highlighted = detail_view.highlight_project_files(backtrace)

      expect(highlighted[0]).to include("spec/models/user_spec.rb")
      expect(highlighted[1]).to include("/path/to/gem")
    end
  end
end
