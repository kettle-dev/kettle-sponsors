# frozen_string_literal: true

require "optparse"

module Kettle
  module Sponsors
    # kettle-sponsors [--config PATH] [--out DIR] [--check | --verify] [--force]
    #                 [--fetch-logos] [--animate MODE] [--shield-style STYLE]
    #                 [--font STACK] [--font-file PATH] [--coin-metal METAL]
    # kettle-sponsors publish --from PATH --registry PATH
    class CLI
      def initialize(argv, out: $stdout, **_options)
        @argv = argv
        @out = out
        @config = CONFIG_PATH
        @dir = LOCAL_DIR
        @mode = :render
        @force = false
        @from = nil
        @registry = nil
        @theme_overrides = {}
      end

      # @return [Integer] exit status. With --check: 0 when badges are current, 1 when stale.
      def run
        @mode = :publish if @argv.first == "publish" && @argv.shift
        parser.parse!(@argv)
        return publish if @mode == :publish

        loaded = Config.load_all(@config)
        sponsors = loaded[:sponsors]
        theme = @theme_overrides.empty? ? loaded[:theme] : loaded[:theme].with(**@theme_overrides)
        case @mode
        when :check then check(sponsors, theme)
        when :verify then verify(sponsors)
        else render(sponsors, theme)
        end
      rescue Error, OptionParser::ParseError => e
        warn("kettle-sponsors: #{e.message}")
        2
      end

      private

      def publish
        raise Error, "publish requires --from and --registry" unless @from && @registry

        changed = Registry.publish(from: File.expand_path(@from), registry: File.expand_path(@registry))
        @out.puts(changed ? "registry updated: #{@registry}" : "registry unchanged")
        0
      end

      def check(sponsors, theme)
        stale = Renderer.stale?(sponsors, out: @dir, theme: theme)
        @out.puts(stale ? "sponsors changed" : "sponsors unchanged")
        stale ? 1 : 0
      end

      def verify(sponsors)
        results = Verifier.verify(sponsors)
        results.each { |url, ok| @out.puts("#{ok ? "ok     " : "MISSING"} #{url}") }
        results.value?(false) ? 1 : 0
      end

      def render(sponsors, theme)
        base_dir = File.dirname(File.expand_path(@config))
        written = Renderer.render(sponsors, out: @dir, force: @force, theme: theme, base_dir: base_dir)
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
          o.on("--from PATH", "publish: source config with sponsors") { |v| @from = v }
          o.on("--registry PATH", "publish: registry file to merge into") { |v| @registry = v }
          o.on("--force", "render even when unchanged") { @force = true }
          o.on("--fetch-logos", "fetch remote http(s) logo URLs and embed them") { @theme_overrides[:fetch_logos] = true }
          o.on("--animate MODE", "animation mode: #{Theme::ANIMATE_MODES.join(", ")}") { |v| @theme_overrides[:animate] = v }
          o.on("--shield-style STYLE", "small badge style: #{Theme::SHIELD_STYLES.join(", ")}") { |v| @theme_overrides[:shield_style] = v }
          o.on("--font STACK", "CSS font-family stack") { |v| @theme_overrides[:font] = v }
          o.on("--font-file PATH", "font file to subset via pyftsubset and embed") { |v| @theme_overrides[:font_file] = v }
          o.on("--coin-metal METAL", "financial coin style: #{Theme::COIN_METALS.join(", ")}") { |v| @theme_overrides[:coin_metal] = v }
        end
      end
    end
  end
end
