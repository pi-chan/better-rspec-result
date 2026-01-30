# frozen_string_literal: true

require "spec_helper"
require "better_rspec_result/storage/json_storage"
require "tmpdir"
require "fileutils"

RSpec.describe BetterRspecResult::Storage::JsonStorage do
  let(:temp_dir) { Dir.mktmpdir("brr-test") }
  subject(:storage) { described_class.new(temp_dir) }

  let(:sample_result_data) do
    {
      "metadata" => {
        "version" => "0.1.0",
        "timestamp" => "2026-01-26T14:30:15+09:00"
      },
      "summary" => {
        "duration" => 2.5,
        "example_count" => 50,
        "failure_count" => 5
      },
      "examples" => []
    }
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#initialize" do
    it "creates storage directory if it doesn't exist" do
      expect(Dir.exist?(temp_dir)).to be true
    end

    it "sets storage_dir" do
      expect(storage.storage_dir).to eq(temp_dir)
    end

    context "with default storage directory" do
      subject(:storage) { described_class.new }

      it "uses project-based default directory" do
        # Should detect git root and use .better-rspec-results directory there
        expect(storage.storage_dir).to include(described_class::DEFAULT_STORAGE_DIRNAME)
      end
    end
  end

  describe "#save" do
    it "saves result data to JSON file" do
      filepath = storage.save(sample_result_data)
      expect(File.exist?(filepath)).to be true
    end

    it "returns filepath" do
      filepath = storage.save(sample_result_data)
      expect(filepath).to match(/rspec-result-\d{8}-\d{6}-\d{6}\.json$/)
    end

    it "saves valid JSON" do
      filepath = storage.save(sample_result_data)
      loaded_data = JSON.parse(File.read(filepath))
      expect(loaded_data).to eq(sample_result_data)
    end

    it "creates unique filenames for multiple saves" do
      filepath1 = storage.save(sample_result_data)
      filepath2 = storage.save(sample_result_data)
      expect(filepath1).not_to eq(filepath2)
    end
  end

  describe "#load" do
    it "loads result from JSON file" do
      filepath = storage.save(sample_result_data)
      result = storage.load(filepath)
      expect(result).to be_a(BetterRspecResult::Storage::Result)
    end

    it "loads correct data" do
      filepath = storage.save(sample_result_data)
      result = storage.load(filepath)
      expect(result.metadata).to eq(sample_result_data["metadata"])
      expect(result.summary).to eq(sample_result_data["summary"])
    end
  end

  describe "#list_results" do
    it "returns empty array when no results" do
      expect(storage.list_results).to eq([])
    end

    it "returns array of file paths" do
      storage.save(sample_result_data)
      sleep 0.01 # Ensure different timestamps
      storage.save(sample_result_data)
      expect(storage.list_results.size).to eq(2)
    end

    it "returns files sorted by modification time (newest first)" do
      filepath1 = storage.save(sample_result_data)
      sleep 0.1
      filepath2 = storage.save(sample_result_data)
      results = storage.list_results
      expect(results.first).to eq(filepath2)
      expect(results.last).to eq(filepath1)
    end
  end

  describe "#latest_result_file" do
    it "returns nil when no results" do
      expect(storage.latest_result_file).to be_nil
    end

    it "returns the most recent result file" do
      storage.save(sample_result_data)
      sleep 0.1
      filepath2 = storage.save(sample_result_data)
      expect(storage.latest_result_file).to eq(filepath2)
    end
  end

  describe "#latest_result" do
    it "returns nil when no results" do
      expect(storage.latest_result).to be_nil
    end

    it "returns the most recent result" do
      storage.save(sample_result_data)
      sleep 0.1
      modified_data = sample_result_data.merge("summary" => { "example_count" => 100 })
      storage.save(modified_data)

      result = storage.latest_result
      expect(result.example_count).to eq(100)
    end
  end

  describe "#remove" do
    it "removes the specified file" do
      filepath = storage.save(sample_result_data)
      expect(File.exist?(filepath)).to be true

      storage.remove(filepath)
      expect(File.exist?(filepath)).to be false
    end

    it "does nothing if file doesn't exist within storage directory" do
      nonexistent_file = File.join(storage.storage_dir, "nonexistent-file.json")
      expect { storage.remove(nonexistent_file) }.not_to raise_error
    end

    it "raises error for files outside storage directory" do
      expect { storage.remove("/nonexistent/file.json") }.to raise_error(
        BetterRspecResult::Storage::JsonStorage::PathTraversalError
      )
    end
  end

  describe "#clear_all" do
    it "removes all result files" do
      storage.save(sample_result_data)
      sleep 0.01 # Ensure different timestamps
      storage.save(sample_result_data)
      expect(storage.list_results.size).to eq(2)

      storage.clear_all
      expect(storage.list_results).to be_empty
    end
  end

  describe "#cleanup_old_results" do
    it "keeps only MAX_RESULTS files" do
      # Create more than MAX_RESULTS files
      (described_class::MAX_RESULTS + 5).times do |i|
        storage.save(sample_result_data)
        sleep 0.001 if i < described_class::MAX_RESULTS + 4 # Ensure different timestamps
      end

      # save already calls cleanup_old_results, so we should have MAX_RESULTS files
      expect(storage.list_results.size).to eq(described_class::MAX_RESULTS)
    end

    it "keeps the most recent files" do
      # Create files with identifiable data
      first_filepath = storage.save(sample_result_data.merge("metadata" => { "id" => "first" }))
      sleep 0.1
      last_filepath = storage.save(sample_result_data.merge("metadata" => { "id" => "last" }))

      # Mock MAX_RESULTS to 1 for testing
      stub_const("#{described_class}::MAX_RESULTS", 1)

      storage.cleanup_old_results
      expect(File.exist?(last_filepath)).to be true
      expect(File.exist?(first_filepath)).to be false
    end

    it "does nothing when results are under MAX_RESULTS" do
      storage.save(sample_result_data)
      expect { storage.cleanup_old_results }.not_to(change { storage.list_results.size })
    end
  end

  describe "#storage_size" do
    it "returns 0 when no results" do
      expect(storage.storage_size).to eq(0)
    end

    it "returns total size of all result files" do
      storage.save(sample_result_data)
      storage.save(sample_result_data)
      expect(storage.storage_size).to be > 0
    end
  end

  describe "#storage_size_human" do
    it "returns size in bytes for small sizes" do
      expect(storage.storage_size_human).to eq("0 B")
    end

    it "returns size in KB" do
      allow(storage).to receive(:storage_size).and_return(2048)
      expect(storage.storage_size_human).to eq("2.0 KB")
    end

    it "returns size in MB" do
      allow(storage).to receive(:storage_size).and_return(2 * 1024 * 1024)
      expect(storage.storage_size_human).to eq("2.0 MB")
    end

    it "returns size in GB" do
      allow(storage).to receive(:storage_size).and_return(2 * 1024 * 1024 * 1024)
      expect(storage.storage_size_human).to eq("2.0 GB")
    end
  end

  describe "security" do
    describe "path traversal protection" do
      it "raises error for forbidden system directories" do
        expect { described_class.new("/etc/better-rspec") }.to raise_error(
          BetterRspecResult::Storage::JsonStorage::PathTraversalError,
          /system directory/
        )
      end

      it "raises error when loading files outside storage directory" do
        storage.save(sample_result_data)
        expect { storage.load("/etc/passwd") }.to raise_error(
          BetterRspecResult::Storage::JsonStorage::PathTraversalError
        )
      end

      it "raises error when removing files outside storage directory" do
        storage.save(sample_result_data)
        expect { storage.remove("/tmp/some-other-file.json") }.to raise_error(
          BetterRspecResult::Storage::JsonStorage::PathTraversalError
        )
      end

      it "raises error for directory traversal attempts" do
        storage.save(sample_result_data)
        malicious_path = File.join(storage.storage_dir, "..", "..", "etc", "passwd")
        expect { storage.load(malicious_path) }.to raise_error(
          BetterRspecResult::Storage::JsonStorage::PathTraversalError
        )
      end
    end

    describe "file permissions" do
      it "sets restrictive permissions on saved files" do
        filepath = storage.save(sample_result_data)
        file_mode = File.stat(filepath).mode & 0o777
        expect(file_mode).to eq(0o600)
      end
    end
  end
end
