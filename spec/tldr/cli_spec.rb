# frozen_string_literal: true

RSpec.describe TLDR::CLI do
  it 'has a version number' do
    expect(TLDR::CLI::VERSION).not_to be nil
  end
end
