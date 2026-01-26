# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
    add_filter "/vendor/"

    add_group "UI", "lib/better_rspec_result/ui"
    add_group "Storage", "lib/better_rspec_result/storage"
    add_group "Core", "lib/better_rspec_result"

    minimum_coverage 80
  end
end

require "better_rspec_result"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
