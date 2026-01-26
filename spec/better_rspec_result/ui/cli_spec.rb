# frozen_string_literal: true

require "spec_helper"
require "better_rspec_result/ui/cli"
require "better_rspec_result/ui/viewer"
require "tmpdir"
require "fileutils"

RSpec.describe BetterRspecResult::UI::CLI do
  let(:temp_dir) { Dir.mktmpdir("brr-test") }
  let(:storage) { BetterRspecResult::Storage::JsonStorage.new(temp_dir) }

  let(:sample_result_data) do
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
          "status" => "failed",
          "file_path" => "spec/models/user_spec.rb",
          "line_number" => 15,
          "run_time" => 0.05,
          "exception" => {
            "class" => "RSpec::Expectations::ExpectationNotMetError",
            "message" => "expected true, got false",
            "backtrace" => ["spec/models/user_spec.rb:21:in `block (3 levels) in <top>'"]
          }
        }
      ]
    }
  end

  before do
    # Mock storage to use temp directory
    allow_any_instance_of(BetterRspecResult::Storage::JsonStorage)
      .to receive(:storage_dir).and_return(temp_dir)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe ".start" do
    it "creates and runs CLI instance" do
      expect { described_class.start(["--version"]) }.to output(/Better RSpec Result version/).to_stdout
    end
  end

  describe "#run" do
    context "with --version option" do
      it "shows version" do
        expect { described_class.start(["--version"]) }.to output(/Better RSpec Result version/).to_stdout
      end
    end

    context "with --clean option" do
      it "removes all results" do
        storage.save(sample_result_data)
        sleep 0.01
        storage.save(sample_result_data)

        expect { described_class.start(["--clean"]) }.to output(/Removed 2 result/).to_stdout
        expect(storage.list_results).to be_empty
      end
    end

    context "with --list option" do
      it "lists all results" do
        storage.save(sample_result_data)

        expect { described_class.start(["--list"]) }.to output(/Found 1 result/).to_stdout
      end

      it "shows no results message when empty" do
        expect { described_class.start(["--list"]) }.to output(/No results found/).to_stdout
      end
    end

    context "with --copy-failures option" do
      it "copies failure locations to clipboard" do
        storage.save(sample_result_data)
        allow(Clipboard).to receive(:copy).and_return(true)

        expect { described_class.start(["--copy-failures"]) }
          .to output(/Copied 1 failure location/).to_stdout
      end

      it "shows no failures message when all tests pass" do
        passing_data = sample_result_data.merge(
          "summary" => sample_result_data["summary"].merge("failure_count" => 0),
          "examples" => sample_result_data["examples"].map { |ex| ex.merge("status" => "passed") }
        )
        storage.save(passing_data)

        expect { described_class.start(["--copy-failures"]) }
          .to output(/No failed examples/).to_stdout
      end

      it "shows no results message when empty" do
        expect { described_class.start(["--copy-failures"]) }
          .to output(/No results found/).to_stdout
      end
    end

    context "with --help option" do
      it "shows help message" do
        expect { described_class.start(["--help"]) }.to output(/Usage: brr/).to_stdout.and raise_error(SystemExit)
      end
    end

    context "with no options (TUI mode)" do
      it "launches TUI viewer" do
        cli = described_class.new([])
        viewer = instance_double(BetterRspecResult::UI::Viewer)

        allow(BetterRspecResult::UI::Viewer).to receive(:new).and_return(viewer)
        allow(viewer).to receive(:start)

        expect(viewer).to receive(:start)
        cli.run
      end
    end

    context "with --plain option" do
      it "shows latest result in plain text" do
        storage.save(sample_result_data)

        expect { described_class.start(["--plain"]) }.to output(/Better RSpec Result/).to_stdout
      end

      it "shows no results message when empty" do
        expect { described_class.start(["--plain"]) }.to output(/No results found/).to_stdout
      end
    end
  end

  describe "display output (--plain mode)" do
    before do
      storage.save(sample_result_data)
    end

    it "displays metadata" do
      output = capture_stdout { described_class.start(["--plain"]) }
      expect(output).to include("Timestamp: 2026-01-26T14:30:15+09:00")
      expect(output).to include("Duration: 2.5s")
      expect(output).to include("Ruby Version: 3.3.0")
      expect(output).to include("RSpec Version: 3.13.0")
    end

    it "displays summary" do
      output = capture_stdout { described_class.start(["--plain"]) }
      expect(output).to include("Examples: 50")
      expect(output).to include("Failures: 5")
      expect(output).to include("Pending: 2")
      expect(output).to include("Success Rate: 86.0%")
    end

    it "displays failed examples" do
      output = capture_stdout { described_class.start(["--plain"]) }
      expect(output).to include("Failed Examples:")
      expect(output).to include("User validations returns true for valid user")
      expect(output).to include("spec/models/user_spec.rb:15")
      expect(output).to include("RSpec::Expectations::ExpectationNotMetError")
    end

    it "shows FAILED status with red color" do
      output = capture_stdout { described_class.start(["--plain"]) }
      expect(output).to include("\e[31mFAILED\e[0m")
    end

    context "with successful test run" do
      let(:success_result_data) do
        sample_result_data.merge(
          "summary" => {
            "duration" => 2.5,
            "example_count" => 50,
            "failure_count" => 0,
            "pending_count" => 0,
            "errors_outside_of_examples_count" => 0
          },
          "examples" => []
        )
      end

      it "shows PASSED status with green color" do
        storage.save(success_result_data)
        output = capture_stdout { described_class.start(["--plain"]) }
        expect(output).to include("\e[32mPASSED\e[0m")
      end

      it "does not show failed examples section" do
        storage.save(success_result_data)
        output = capture_stdout { described_class.start(["--plain"]) }
        expect(output).not_to include("Failed Examples:")
      end
    end
  end

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
