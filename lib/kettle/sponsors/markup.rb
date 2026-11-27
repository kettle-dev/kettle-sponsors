# frozen_string_literal: true

require "cgi"

module Kettle
  module Sponsors
    # Builds the linked, responsive badge markup:
    #   <a href><picture><source phone><img desktop></picture></a>
    # Badges are concatenated without whitespace so they tile as a grid.
    # Also builds compact single-line Shields.io-style badge parade markup.
    module Markup
      module_function

      # @param sponsor [Sponsor]
      # @param base [String] URL or relative path of the directory holding the SVGs
      # @param width [String] CSS/HTML width attribute for grid tiling
      # @param _options [Hash] forward-compatible options
      # @return [String]
      def badge(sponsor, base:, width: "25%", **_options)
        base = base.chomp("/")
        alt = CGI.escapeHTML("Sponsor: #{sponsor.name}#{" - #{sponsor.description}" unless sponsor.description.empty?}")
        picture = %(<picture><source media="(max-width: 600px)" srcset="#{base}/phone/#{sponsor.slug}.svg">) +
          %(<img src="#{base}/#{sponsor.slug}.svg" width="#{width}" align="top" alt="#{alt}"></picture>)
        return picture if sponsor.href.empty?

        %(<a href="#{CGI.escapeHTML(sponsor.href)}">#{picture}</a>)
      end

      # @param sponsors [Array<Sponsor>]
      # @param central_base [String]
      # @param local_base [String]
      # @param width [String]
      # @param today [Date]
      # @param options [Hash] forward-compatible options
      # @return [String]
      def badges(sponsors, central_base: CENTRAL_BASE, local_base: LOCAL_DIR, width: "25%", today: Date.today, **options)
        sponsors.select { |s| s.active?(today) }.map do |s|
          badge(s, base: s.local? ? local_base : central_base, width: width, **options)
        end.join
      end

      # Build a single compact Shields.io-style badge tag for a README badge parade.
      #
      # @param sponsor [Sponsor]
      # @param base [String] URL or relative path holding +shield/<slug>.svg+
      # @param _options [Hash] forward-compatible options
      # @return [String]
      def shield(sponsor, base:, **_options)
        base = base.chomp("/")
        label = sponsor.label || Icons.shield_label(sponsor.kind)
        alt = CGI.escapeHTML("#{label}: #{sponsor.name}")
        img = %(<img src="#{base}/shield/#{sponsor.slug}.svg" alt="#{alt}">)
        return img if sponsor.href.empty?

        %(<a href="#{CGI.escapeHTML(sponsor.href)}">#{img}</a>)
      end

      # Build a space-separated single-line parade of compact Shields-style badges.
      #
      # @param sponsors [Array<Sponsor>]
      # @param central_base [String]
      # @param local_base [String]
      # @param today [Date]
      # @param options [Hash] forward-compatible options
      # @return [String]
      def shields(sponsors, central_base: CENTRAL_BASE, local_base: LOCAL_DIR, today: Date.today, **options)
        sponsors.select { |s| s.active?(today) }.map do |s|
          shield(s, base: s.local? ? local_base : central_base, **options)
        end.join(" ")
      end
    end
  end
end
