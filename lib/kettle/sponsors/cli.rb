# frozen_string_literal: true

require "optparse"

module Kettle
  module Sponsors
    # kettle-sponsors [--config PATH] [--out DIR] [--check | --verify] [--force]
    class CLI
      def initialize(argv, out: $stdout)
        @argv = argv
        @out = out
        @config = CONFIG_PATH
        @dir = LOCAL_DIR
        @mode = :render
        @force = false
      end

      # @return [Integer] exit status. With --check: 0 when badges are current, 1 when stale.
      def run
        parser.parse!(@argv)
        sponsors = Config.load(@config)
        case @mode
        when :check then check(sponsors)
        when :verify then verify(sponsors)
        else render(sponsors)
        end
      rescue Error, OptionParser::ParseError => e
        warn("kettle-sponsors: #{e.message}")
        2
      end

      private

      def check(sponsors)
        stale = Renderer.stale?(sponsors, out: @dir)
        @out.puts(stale ? "sponsors changed" : "sponsors unchanged")
        stale ? 1 : 0
      end

      def verify(sponsors)
        results = Verifier.verify(sponsors)
        results.each { |url, ok| @out.puts("#{ok ? "ok     " : "MISSING"} #{url}") }
        results.value?(false) ? 1 : 0
      end

      def render(sponsors)
        written = Renderer.render(sponsors, out: @dir, force: @force)
        @out.puts(written.empty? ? "sponsor badges up to date" : "rendered #{written.size} file(s)")
        0
      end

      def parser
        OptionParser.new do |o|
          o.banner = "Usage: kettle-sponsors [options]"
          o.on("--config PATH", "kettle-jem.yml or registry (default #{CONFIG_PATH})") { |v| @config = v }
          o.on("--out DIR", "output directory (default #{LOCAL_DIR})") { |v| @dir = v }
          o.on("--check", "exit 1 if badges are stale, 0 if current") { @mode = :check }
          o.on("--verify", "HEAD-check central badge URLs (network)") { @mode = :verify }
          o.on("--force", "render even when unchanged") { @force = true }
        end
      end
    end
  end
end
