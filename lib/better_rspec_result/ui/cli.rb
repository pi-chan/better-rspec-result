# frozen_string_literal: true

require "optparse"
require_relative "../storage/json_storage"
require_relative "../version"

module BetterRspecResult
  module UI
    # Command-line interface for Better RSpec Result
    class CLI
          def self.start(args)
            new(args).run
          end

          def initialize(args)
            @args = args
            @storage = Storage::JsonStorage.new
            @options = {}
            parse_options
          end

          def run
            if @options[:version]
              show_version
            elsif @options[:clean]
              clean_results
            elsif @options[:list]
              list_results
            elsif @options[:plain]
              show_latest_result
            else
              launch_tui
            end
          end

          private

          def launch_tui
            require_relative "viewer"
            require_relative "components/color_scheme"
            require_relative "components/formatter"
            require_relative "key_bindings"

            viewer = Viewer.new(storage: @storage)
            viewer.start
          rescue Interrupt
            puts "\nExiting..."
            exit(0)
          end

          def parse_options
            OptionParser.new do |opts|
              opts.banner = "Usage: brr [options]"

              opts.on("-p", "--plain", "Show plain text output (legacy mode)") do
                @options[:plain] = true
              end

              opts.on("-v", "--version", "Show version") do
                @options[:version] = true
              end

              opts.on("-c", "--clean", "Remove all stored results") do
                @options[:clean] = true
              end

              opts.on("-l", "--list", "List all stored results") do
                @options[:list] = true
              end

              opts.on("-h", "--help", "Show this help message") do
                puts opts
                exit
              end
            end.parse!(@args)
          end

          def show_version
            puts "Better RSpec Result version #{BetterRspecResult::VERSION}"
          end

          def clean_results
            result_count = @storage.list_results.size
            @storage.clear_all
            puts "Removed #{result_count} result(s)"
            puts "Storage directory: #{@storage.storage_dir}"
          end

          def list_results
            results = @storage.list_results
            if results.empty?
              puts "No results found in #{@storage.storage_dir}"
              return
            end

            puts "Found #{results.size} result(s) in #{@storage.storage_dir}"
            puts "Total size: #{@storage.storage_size_human}"
            puts

            results.each_with_index do |filepath, index|
              result = @storage.load(filepath)
              timestamp = result.timestamp
              status = result.success? ? "PASSED" : "FAILED"
              status_color = result.success? ? "\e[32m" : "\e[31m"
              reset_color = "\e[0m"

              puts "#{index + 1}. #{status_color}#{status}#{reset_color} - #{timestamp}"
              puts "   #{result.example_count} examples, #{result.failure_count} failures, #{result.pending_count} pending"
              puts "   Duration: #{result.duration.round(2)}s"
              puts "   File: #{File.basename(filepath)}"
              puts
            end
          end

          def show_latest_result
            result = @storage.latest_result
            unless result
              puts "No results found in #{@storage.storage_dir}"
              puts "Run RSpec with --format BetterRspecResult::Formatter to save results"
              return
            end

            display_result(result)
          end

          def display_result(result)
            puts "=" * 80
            puts "Better RSpec Result"
            puts "=" * 80
            puts

            # Metadata
            puts "Timestamp: #{result.timestamp}"
            puts "Duration: #{result.duration.round(2)}s"
            puts "Command: #{result.metadata['command']}" if result.metadata['command']
            puts "Working Directory: #{result.metadata['working_directory']}"
            puts "Ruby Version: #{result.metadata['ruby_version']}"
            puts "RSpec Version: #{result.metadata['rspec_version']}"
            puts

            # Summary
            status = result.success? ? "\e[32mPASSED\e[0m" : "\e[31mFAILED\e[0m"
            puts "Status: #{status}"
            puts "Examples: #{result.example_count}"
            puts "Failures: #{result.failure_count}"
            puts "Pending: #{result.pending_count}"
            puts "Success Rate: #{result.success_rate}%"
            puts

            # Failed examples
            if result.failed?
              puts "=" * 80
              puts "Failed Examples:"
              puts "=" * 80
              puts

              result.failed_examples.each_with_index do |example, index|
                puts "#{index + 1}. #{example['full_description']}"
                puts "   Location: #{example['file_path']}:#{example['line_number']}"
                if example['exception']
                  puts "   Error: #{example['exception']['class']}: #{example['exception']['message']}"
                end
                puts
              end
            end

            puts "=" * 80
            puts "Use 'brr --list' to see all results"
            puts "Use 'brr --clean' to remove all results"
            puts "=" * 80
          end
        end
      end
    end
