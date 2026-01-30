# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc "Run security audit on dependencies"
task :audit do
  require "bundler/audit/cli"
  Bundler::Audit::CLI.start ["check", "--update"]
end

task default: :spec
