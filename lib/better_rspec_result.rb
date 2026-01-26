# frozen_string_literal: true

require_relative "better_rspec_result/version"
require_relative "better_rspec_result/storage/result"
require_relative "better_rspec_result/storage/json_storage"
require_relative "better_rspec_result/formatter"

module BetterRspecResult
  class Error < StandardError; end
end
