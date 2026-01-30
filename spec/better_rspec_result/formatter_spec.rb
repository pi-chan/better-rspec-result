# frozen_string_literal: true

require "spec_helper"
require "better_rspec_result/formatter"
require "stringio"
require "tmpdir"
require "fileutils"

RSpec.describe BetterRspecResult::Formatter do
  let(:output) { StringIO.new }
  let(:temp_dir) { Dir.mktmpdir("brr-test") }
  subject(:formatter) { described_class.new(output) }

  before do
    # Mock storage to use temp directory
    allow_any_instance_of(BetterRspecResult::Storage::JsonStorage)
      .to receive(:storage_dir).and_return(temp_dir)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#start" do
    let(:notification) { double("notification", count: 10) }

    it "captures start time" do
      expect { formatter.start(notification) }.not_to raise_error
    end
  end

  describe "#example_passed" do
    let(:example) do
      double(
        "example",
        id: "./spec/example_spec.rb[1:1:1]",
        description: "passes",
        full_description: "Example passes",
        metadata: { file_path: "spec/example_spec.rb", line_number: 10 },
        execution_result: double(run_time: 0.05),
        exception: nil
      )
    end
    let(:notification) { double("notification", example: example) }

    it "captures passed example" do
      expect { formatter.example_passed(notification) }.not_to raise_error
    end
  end

  describe "#example_failed" do
    let(:exception) do
      raise "Test error"
    rescue StandardError => e
      e
    end
    let(:example) do
      double(
        "example",
        id: "./spec/example_spec.rb[1:1:2]",
        description: "fails",
        full_description: "Example fails",
        metadata: { file_path: "spec/example_spec.rb", line_number: 20 },
        execution_result: double(run_time: 0.03),
        exception: exception
      )
    end
    let(:notification) { double("notification", example: example) }

    it "captures failed example with exception" do
      expect { formatter.example_failed(notification) }.not_to raise_error
    end
  end

  describe "#example_pending" do
    let(:example) do
      double(
        "example",
        id: "./spec/example_spec.rb[1:1:3]",
        description: "is pending",
        full_description: "Example is pending",
        metadata: { file_path: "spec/example_spec.rb", line_number: 30 },
        execution_result: double(run_time: 0.0),
        exception: nil
      )
    end
    let(:notification) { double("notification", example: example) }

    it "captures pending example" do
      expect { formatter.example_pending(notification) }.not_to raise_error
    end
  end

  describe "#dump_summary" do
    let(:notification) do
      double(
        "notification",
        duration: 2.5,
        example_count: 10,
        failure_count: 2,
        pending_count: 1,
        errors_outside_of_examples_count: 0
      )
    end

    it "captures summary" do
      expect { formatter.dump_summary(notification) }.not_to raise_error
    end
  end

  describe "#close" do
    let(:start_notification) { double("notification", count: 10) }
    let(:summary_notification) do
      double(
        "notification",
        duration: 2.5,
        example_count: 10,
        failure_count: 2,
        pending_count: 1,
        errors_outside_of_examples_count: 0
      )
    end

    it "saves results to JSON file" do
      formatter.start(start_notification)
      formatter.dump_summary(summary_notification)

      expect { formatter.close(double("notification")) }.not_to raise_error

      # Check that file was created
      files = Dir.glob(File.join(temp_dir, "rspec-result-*.json"))
      expect(files).not_to be_empty
    end

    it "outputs save confirmation message" do
      formatter.start(start_notification)
      formatter.dump_summary(summary_notification)
      formatter.close(double("notification"))

      output.rewind
      expect(output.read).to include("Better RSpec Result saved to:")
    end

    it "saves correct data structure" do
      formatter.start(start_notification)
      formatter.dump_summary(summary_notification)
      formatter.close(double("notification"))

      files = Dir.glob(File.join(temp_dir, "rspec-result-*.json"))
      data = JSON.parse(File.read(files.first))

      expect(data).to include("metadata", "summary", "examples")
      expect(data["metadata"]).to include("version", "timestamp", "command")
      expect(data["summary"]).to include("duration", "example_count", "failure_count")
    end
  end

  describe "integration test" do
    it "captures full test run" do
      start_notification = double("notification", count: 3)
      formatter.start(start_notification)

      # Passed example
      passed_example = double(
        "example",
        id: "./spec/example_spec.rb[1:1:1]",
        description: "passes",
        full_description: "Example passes",
        metadata: { file_path: "spec/example_spec.rb", line_number: 10 },
        execution_result: double(run_time: 0.05),
        exception: nil
      )
      formatter.example_passed(double("notification", example: passed_example))

      # Failed example
      exception = begin
        raise "Test error"
      rescue StandardError => e
        e
      end
      failed_example = double(
        "example",
        id: "./spec/example_spec.rb[1:1:2]",
        description: "fails",
        full_description: "Example fails",
        metadata: { file_path: "spec/example_spec.rb", line_number: 20 },
        execution_result: double(run_time: 0.03),
        exception: exception
      )
      formatter.example_failed(double("notification", example: failed_example))

      # Pending example
      pending_example = double(
        "example",
        id: "./spec/example_spec.rb[1:1:3]",
        description: "is pending",
        full_description: "Example is pending",
        metadata: { file_path: "spec/example_spec.rb", line_number: 30 },
        execution_result: double(run_time: 0.0),
        exception: nil
      )
      formatter.example_pending(double("notification", example: pending_example))

      # Summary
      summary_notification = double(
        "notification",
        duration: 2.5,
        example_count: 3,
        failure_count: 1,
        pending_count: 1,
        errors_outside_of_examples_count: 0
      )
      formatter.dump_summary(summary_notification)

      # Close
      formatter.close(double("notification"))

      # Verify saved data
      files = Dir.glob(File.join(temp_dir, "rspec-result-*.json"))
      data = JSON.parse(File.read(files.first))

      expect(data["examples"].size).to eq(3)
      expect(data["examples"][0]["status"]).to eq("passed")
      expect(data["examples"][1]["status"]).to eq("failed")
      expect(data["examples"][1]["exception"]).to include("class", "message", "backtrace")
      expect(data["examples"][2]["status"]).to eq("pending")
    end
  end

  describe "security" do
    describe "command line sanitization" do
      let(:start_notification) { double("notification", count: 1) }
      let(:summary_notification) do
        double(
          "notification",
          duration: 1.0,
          example_count: 1,
          failure_count: 0,
          pending_count: 0,
          errors_outside_of_examples_count: 0
        )
      end

      it "masks sensitive arguments in saved metadata" do
        original_argv = ARGV.dup
        begin
          ARGV.replace(["--api-key=secret123", "--other-flag"])

          formatter.start(start_notification)
          formatter.dump_summary(summary_notification)
          formatter.close(double("notification"))

          files = Dir.glob(File.join(temp_dir, "rspec-result-*.json"))
          data = JSON.parse(File.read(files.first))

          expect(data["metadata"]["command"]).to include("--api-key=[FILTERED]")
          expect(data["metadata"]["command"]).to include("--other-flag")
          expect(data["metadata"]["command"]).not_to include("secret123")
        ensure
          ARGV.replace(original_argv)
        end
      end

      it "masks password arguments" do
        original_argv = ARGV.dup
        begin
          ARGV.replace(["--password=mypassword", "--db-password=dbpass"])

          formatter.start(start_notification)
          formatter.dump_summary(summary_notification)
          formatter.close(double("notification"))

          files = Dir.glob(File.join(temp_dir, "rspec-result-*.json"))
          data = JSON.parse(File.read(files.first))

          expect(data["metadata"]["command"]).not_to include("mypassword")
          expect(data["metadata"]["command"]).not_to include("dbpass")
        ensure
          ARGV.replace(original_argv)
        end
      end

      it "masks token arguments" do
        original_argv = ARGV.dup
        begin
          ARGV.replace(["--auth-token=abc123"])

          formatter.start(start_notification)
          formatter.dump_summary(summary_notification)
          formatter.close(double("notification"))

          files = Dir.glob(File.join(temp_dir, "rspec-result-*.json"))
          data = JSON.parse(File.read(files.first))

          expect(data["metadata"]["command"]).not_to include("abc123")
        ensure
          ARGV.replace(original_argv)
        end
      end
    end
  end
end
