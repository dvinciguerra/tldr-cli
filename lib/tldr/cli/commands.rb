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

      LOCAL_BASE =
        ENV.fetch('TLDR_LOCAL_BASE', "#{Dir.home}/.config/tldr/pages")

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

      option :lang do
        optional
        short '-l'
        long '--lang=string'
        default 'en'
        permit %w[ar bn bs ca cs da de en es fa fi fr hi id it ja ko lo ml ne nl no pl pt_BR pt_PT ro ru sh sr sv ta th
                  tr uk uz zh zh_TW]
        desc 'select language of page to be displayed (default: en)'
      end

      option :platform do
        optional
        short '-p'
        long '--platform=string'
        default 'common'
        permit %w[linux osx sunos windows common]
        desc 'select platform, supported are linux / osx / sunos / windows / common'
      end

      option :source do
        optional
        short '-s'
        long '--source=string'
        default 'local'
        permit %w[local remote]
        desc 'select page source to be local or remote (default: local)'
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
          query, lang, platform, source =
            params.to_h.values_at(:query, :lang, :platform, :source)

          page_path = "/#{platform}/#{query}"

          if source == 'local' && local_page?(local_path(page_path, lang: lang))
            content = File.read(local_path(page_path, lang: lang))
            render_markdown(content)
            return
          end

          response = Faraday.get(remote_path(page_path, lang: lang))
          return not_found unless response.success?

          render_markdown(response.body)
        else
          print help
        end
      end

      private

      def render_markdown(content)
        puts TTY::Markdown.parse(content, symbols: { override: { bullet: '-' } })
      end

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

      def local_page?(page_path)
        File.exist?(page_path)
      end

      def local_path(fragment, lang: 'en', relative: false)
        lang = lang == 'en' ? '' : ".#{lang}"
        "#{relative ? '' : LOCAL_BASE}#{lang}#{fragment}#{URL_SUFFIX}"
      end

      def remote_path(fragment, lang: 'en', relative: false)
        lang = lang == 'en' ? '' : ".#{lang}"
        "#{relative ? '' : URL_BASE}#{lang}#{fragment}#{URL_SUFFIX}"
      end
    end
  end
end
