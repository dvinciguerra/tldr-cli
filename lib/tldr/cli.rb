# frozen_string_literal: true

require_relative 'cli/version'
require_relative 'cli/commands'

module TLDR
  module CLI
    class Error < StandardError; end

    def self.execute
      commands = Commands.new
      commands.run
    end
  end
end
