# frozen_string_literal: true

require "cgi"

module Kettle
  module Sponsors
    # Builds the linked, responsive badge markup:
    #   <a href><picture><source phone><img desktop></picture></a>
    # Badges are concatenated without whitespace so they tile as a grid.
    module Markup
      module_function

      # @param base [String] URL or relative path of the directory holding the SVGs
      def badge(sponsor, base:, width: "25%")
        base = base.chomp("/")
        alt = CGI.escapeHTML("Sponsor: #{sponsor.name}#{" - #{sponsor.description}" unless sponsor.description.empty?}")
        picture = %(<picture><source media="(max-width: 600px)" srcset="#{base}/phone/#{sponsor.slug}.svg">) +
          %(<img src="#{base}/#{sponsor.slug}.svg" width="#{width}" align="top" alt="#{alt}"></picture>)
        return picture if sponsor.href.empty?

        %(<a href="#{CGI.escapeHTML(sponsor.href)}">#{picture}</a>)
      end

      def badges(sponsors, central_base: CENTRAL_BASE, local_base: LOCAL_DIR, width: "25%", today: Date.today)
        sponsors.select { |s| s.active?(today) }.map do |s|
          badge(s, base: s.local? ? local_base : central_base, width: width)
        end.join
      end
    end
  end
end
