# frozen_string_literal: true

RSpec.describe BetterRspecResult do
  it "has a version number" do
    expect(BetterRspecResult::VERSION).not_to be nil
  end

  it "has an Error class" do
    expect(BetterRspecResult::Error).to be < StandardError
  end
end
