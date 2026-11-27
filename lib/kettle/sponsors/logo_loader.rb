# frozen_string_literal: true

require "digest"
require "fileutils"
require "net/http"
require "uri"

module Kettle
  module Sponsors
    # Resolves a sponsor logo reference into a self-contained +data:+ URI so
    # rendered SVGs display logos even inside GitHub README +<img>+ tags
    # (where browsers block external image requests inside SVGs).
    module LogoLoader
      MIME_BY_EXT = {
        ".svg" => "image/svg+xml",
        ".png" => "image/png",
        ".jpg" => "image/jpeg",
        ".jpeg" => "image/jpeg",
        ".webp" => "image/webp"
      }.freeze

      EXT_BY_MIME = {
        "image/svg+xml" => ".svg",
        "image/png" => ".png",
        "image/jpeg" => ".jpg",
        "image/webp" => ".webp"
      }.freeze

      MAX_REDIRECTS = 3

      module_function

      # Resolve a logo path, data URI, or optional remote URL to a +data:+ URI.
      #
      # @param logo [String, nil] local file path, +data:image/...+ URI, or +http(s)://+ URL
      # @param base_dir [String, nil] directory used to resolve relative local paths
      # @param fetch [Boolean] allow fetching remote +http(s)://+ URLs (default false)
      # @param cache_dir [String, nil] directory for caching fetched remote logos
      # @param refresh [Boolean] ignore cached remote logos and re-fetch
      # @param http [#call] injectable HTTP fetcher returning +[bytes, content_type]+ or +nil+
      # @param _options [Hash] forward-compatible options
      # @return [String, nil] +data:<mime>;base64,...+ URI or +nil+
      def resolve(logo, base_dir: nil, fetch: false, cache_dir: nil, refresh: false, http: method(:fetch_bytes), **_options)
        source = logo.to_s.strip
        return if source.empty?
        return source if source.start_with?("data:image/")
        return resolve_remote(source, cache_dir: cache_dir, refresh: refresh, http: http) if remote?(source) && fetch
        return if remote?(source)

        resolve_local(source, base_dir: base_dir)
      end

      # @param source [String]
      # @return [Boolean]
      def remote?(source)
        source.match?(%r{\Ahttps?://}i)
      end

      # Detect image MIME type from raw bytes, HTTP Content-Type, or file extension.
      #
      # @param bytes [String]
      # @param path_or_url [String, nil]
      # @param content_type [String, nil]
      # @return [String, nil]
      def detect_mime(bytes, path_or_url: nil, content_type: nil)
        return "image/png" if bytes.start_with?("\x89PNG".b)
        return "image/jpeg" if bytes.start_with?("\xFF\xD8".b)
        return "image/webp" if bytes.bytesize >= 12 && bytes[0, 4] == "RIFF".b && bytes[8, 4] == "WEBP".b

        head = bytes.byteslice(0, 256).to_s.lstrip
        return "image/svg+xml" if head.start_with?("<svg", "<?xml") && head.include?("<svg")

        ct = content_type.to_s.split(";").first.to_s.strip.downcase
        return ct if EXT_BY_MIME.key?(ct)

        ext = File.extname(path_or_url.to_s.split("?").first.to_s).downcase
        MIME_BY_EXT[ext]
      end

      def resolve_local(source, base_dir:)
        candidates = [source]
        candidates << File.expand_path(source, base_dir) if base_dir && !absolute_path?(source)
        path = candidates.find { |p| File.file?(p) }
        return unless path

        bytes = File.binread(path)
        mime = detect_mime(bytes, path_or_url: path)
        return unless mime

        encode_data_uri(bytes, mime)
      end

      def resolve_remote(url, cache_dir:, refresh:, http:)
        if cache_dir && !refresh
          cached = read_cached(cache_dir, url)
          return cached if cached
        end

        result = http.call(url)
        return unless result

        bytes, content_type = result.is_a?(Array) ? result : [result, nil]
        return if bytes.nil? || bytes.empty?

        mime = detect_mime(bytes, path_or_url: url, content_type: content_type)
        return unless mime

        write_cached(cache_dir, url, bytes, mime) if cache_dir
        encode_data_uri(bytes, mime)
      end

      def encode_data_uri(bytes, mime)
        "data:#{mime};base64,#{[bytes].pack("m0")}"
      end

      def cache_key(url)
        Digest::SHA256.hexdigest(url)[0, 16]
      end

      def read_cached(cache_dir, url)
        key = cache_key(url)
        EXT_BY_MIME.each do |mime, ext|
          path = File.join(cache_dir, "#{key}#{ext}")
          return encode_data_uri(File.binread(path), mime) if File.file?(path)
        end
        nil
      end

      def write_cached(cache_dir, url, bytes, mime)
        ext = EXT_BY_MIME[mime]
        return unless ext

        FileUtils.mkdir_p(cache_dir)
        File.binwrite(File.join(cache_dir, "#{cache_key(url)}#{ext}"), bytes)
      end

      def fetch_bytes(url, redirects: MAX_REDIRECTS)
        uri = URI(url)
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 5) do |http|
          req = Net::HTTP::Get.new(uri)
          req["User-Agent"] = "kettle-sponsors/#{VERSION}"
          res = http.request(req)
          if res.is_a?(Net::HTTPRedirection) && res["location"] && redirects.positive?
            target = URI.join(uri, res["location"]).to_s
            return fetch_bytes(target, redirects: redirects - 1)
          end
          return [res.body.b, res["content-type"]] if res.is_a?(Net::HTTPSuccess)
        end
        nil
      rescue SystemCallError, Net::OpenTimeout, Net::ReadTimeout, SocketError, URI::InvalidURIError
        nil
      end

      def absolute_path?(path)
        path.start_with?("/") || path.match?(/\A[A-Za-z]:[\/\\]/)
      end
    end
  end
end
