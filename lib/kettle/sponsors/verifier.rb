# frozen_string_literal: true

require "net/http"
require "uri"

module Kettle
  module Sponsors
    # Opt-in check that central badges exist. Never runs during templating.
    module Verifier
      module_function

      # @return [Hash{String=>Boolean}] central URL => reachable
      def verify(sponsors, base: CENTRAL_BASE, today: Date.today, http: method(:head))
        sponsors.select { |s| s.active?(today) && !s.local? }.each_with_object({}) do |s, result|
          %W[#{base}/#{s.slug}.svg #{base}/phone/#{s.slug}.svg].each { |url| result[url] = http.call(url) }
        end
      end

      def head(url)
        uri = URI(url)
        Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |h|
          h.head(uri.path).is_a?(Net::HTTPSuccess)
        end
      rescue SystemCallError, Net::OpenTimeout, Net::ReadTimeout, SocketError
        false
      end
    end
  end
end
