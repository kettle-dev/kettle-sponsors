# frozen_string_literal: true

require "open3"
require "tmpdir"

module Kettle
  module Sponsors
    # Subsets a custom font file to only the characters rendered in an SVG via
    # +pyftsubset+ (from +fonttools+) and returns an embedded +@font-face+ CSS
    # rule using a +data:+ URI.
    #
    # Falls back to embedding the full source font if +pyftsubset+ is not
    # installed on +PATH+.
    module FontSubsetter
      FORMAT_BY_EXT = {
        ".woff2" => ["font/woff2", "woff2"],
        ".woff" => ["font/woff", "woff"],
        ".ttf" => ["font/ttf", "truetype"],
        ".otf" => ["font/otf", "opentype"]
      }.freeze

      module_function

      # Build an embedded +@font-face+ CSS rule for +font_file+ subsetted to
      # the unique characters present in +text+.
      #
      # @param font_file [String] path to +.ttf+, +.otf+, +.woff+, or +.woff2+
      # @param text [String] concatenated text rendered inside the SVG
      # @param family [String, nil] CSS font-family name (defaults to sanitized basename)
      # @param command [String] subsetter executable (default +"pyftsubset"+)
      # @param runner [#call, nil] injectable command runner +(cmd_array) -> [stdout, stderr, success]+
      # @param _options [Hash] forward-compatible options
      # @return [Hash{Symbol => Object}] +{family:, css:, subsetted:, chars:}+
      # @raise [Kettle::Sponsors::Error] if +font_file+ does not exist or has unsupported format
      def css_for(font_file:, text:, family: nil, command: "pyftsubset", runner: nil, **_options)
        raise Error, "font_file not found: #{font_file}" unless File.file?(font_file)

        ext = File.extname(font_file).downcase
        mime, fmt = FORMAT_BY_EXT[ext]
        raise Error, "unsupported font format #{ext.inspect} for #{font_file}" unless mime

        chars = unique_chars(text)
        font_name = normalize_family(family || File.basename(font_file, ext))
        bytes, out_mime, out_fmt, subsetted = subset_bytes(
          font_file: font_file,
          chars: chars,
          fallback_mime: mime,
          fallback_fmt: fmt,
          command: command,
          runner: runner
        )
        encoded = [bytes].pack("m0")
        css = "@font-face{font-family:'#{font_name}';src:url(data:#{out_mime};base64,#{encoded}) format('#{out_fmt}');font-display:block;}"
        {family: font_name, css: css, subsetted: subsetted, chars: chars}
      end

      # @param text [String]
      # @return [String] deterministic sorted string of unique characters
      def unique_chars(text)
        text.to_s.chars.uniq.sort.join
      end

      def normalize_family(name)
        cleaned = name.to_s.gsub(/[^A-Za-z0-9 _-]/, "").strip
        cleaned.empty? ? "SponsorFont" : cleaned
      end

      def subset_bytes(font_file:, chars:, fallback_mime:, fallback_fmt:, command:, runner:)
        return [File.binread(font_file), fallback_mime, fallback_fmt, false] if chars.empty?

        exec = runner || method(:run_command)
        Dir.mktmpdir do |dir|
          woff2_out = File.join(dir, "subset.woff2")
          _, _, ok = exec.call([command, font_file, "--text=#{chars}", "--flavor=woff2", "--output-file=#{woff2_out}"])
          return [File.binread(woff2_out), "font/woff2", "woff2", true] if ok && File.file?(woff2_out)

          raw_out = File.join(dir, "subset#{File.extname(font_file).downcase}")
          _, _, ok = exec.call([command, font_file, "--text=#{chars}", "--output-file=#{raw_out}"])
          return [File.binread(raw_out), fallback_mime, fallback_fmt, true] if ok && File.file?(raw_out)
        end

        [File.binread(font_file), fallback_mime, fallback_fmt, false]
      rescue Errno::ENOENT
        [File.binread(font_file), fallback_mime, fallback_fmt, false]
      end

      def run_command(argv)
        stdout, stderr, status = Open3.capture3(*argv)
        [stdout, stderr, status.success?]
      end
    end
  end
end
