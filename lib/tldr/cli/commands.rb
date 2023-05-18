# frozen_string_literal: true

require 'faraday'
require 'tty-option'
require 'tty-markdown'

module TLDR
  module CLI
    class Commands
      include TTY::Option

      URL_BASE =
        ENV.fetch('TLDR_URL_BASE', 'https://raw.githubusercontent.com/tldr-pages/tldr/main/pages')

      URL_SUFFIX =
        ENV.fetch('TLDR_URL_SUFFIX', '.md')

      usage do
        program 'tldr'

        banner "usage: #{program} [-v] [OPTION]... SEARCH"
      end

      flag :version do
        optional
        short '-v'
        long '--version'
        desc 'print version and exit'
      end

      flag :help do
        optional
        short '-h'
        long '--help'
        desc 'print this help and exit'
      end

      # flag :update do
      #   optional
      #   short '-u'
      #   long '--update'
      #   desc 'update local database [not implemented]'
      # end

      # flag :'clear-cache' do
      #   optional
      #   short '-c'
      #   long '--clear-cache'
      #   desc 'clear local database'
      # end

      # option :render do
      #   optional
      #   short '-r'
      #   long '--render=[string]'
      #   desc 'render a local page for testing purposes'
      # end

      # flag :list do
      #   optional
      #   short '-l'
      #   long '--list'
      #   desc 'list all entries in the local database'
      # end

      option :platform do
        optional
        short '-p'
        long '--platform=string'
        default 'common'
        permit %w[linux osx sunos windows common]
        desc 'select platform, supported are linux / osx / sunos / windows / common'
      end

      argument :query do
        arity zero_or_more
      end

      def run
        parse

        if params.errors.any?
          puts params.errors.summary
        elsif params[:help]
          print help
        elsif params[:version]
          version
        elsif params[:query]
          query = params[:query]
          platform = params[:platform]

          response = Faraday.get("#{URL_BASE}/#{platform}/#{query}#{URL_SUFFIX}")

          return not_found unless response.success?

          markdown = TTY::Markdown.parse(response.body, symbols: { override: { bullet: '-' } })
          puts markdown
        else
          print help
        end
      end

      private

      def version
        puts <<~MESSAGE
          tldr v#{TLDR::CLI::VERSION} (v#{TLDR::CLI::VERSION})
          Copyright (C) 2023 Daniel Vinciguerra
          Source available at https://github.com/dvinciguerra/tldr-cli
        MESSAGE
      end

      def not_found
        puts <<~MESSAGE
          This page doesn't exist yet!
          Submit new pages here: https://github.com/tldr-pages/tldr
        MESSAGE
      end
    end
  end
end
