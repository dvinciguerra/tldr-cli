# frozen_string_literal: true

RSpec.describe TLDR::CLI::Commands do
  subject(:instance) { described_class.new }

  it 'instance responds to run' do
    expect(instance).to respond_to(:run)
  end

  it 'instance responds to parse' do
    expect(instance).to respond_to(:parse)
  end
end
