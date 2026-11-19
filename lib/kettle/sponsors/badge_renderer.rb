# frozen_string_literal: true

require "cgi"

module Kettle
  module Sponsors
    # Deterministic SVG for one sponsor. Same input always yields the same bytes.
    module BadgeRenderer
      VARIANTS = %i[desktop phone].freeze
      FONT = "system-ui,sans-serif"

      module_function

      def svg(sponsor, variant: :desktop)
        raise ArgumentError, "unknown variant #{variant.inspect}" unless VARIANTS.include?(variant)

        phone = variant == :phone
        scale = phone ? 0.8 : 1.0
        since = sponsor.since ? "since #{sponsor.since.iso8601[0, 7]}" : "sponsor"
        desc = sponsor.description
        desc = "#{desc[0, 40]}…" if phone && desc.length > 40
        w = ([190, (sponsor.name.length * 9) + 40, (desc.length * 6) + 28].max * scale).round
        h = ((desc.empty? ? 40 : 54) * scale).round
        label = [sponsor.name, since, desc].reject(&:empty?).join(", ")
        s = ->(n) { (n * scale).round(1).to_s.sub(/\.0\z/, "") }
        extra = desc.empty? ? "" : %(\n  <text x="#{s[14]}" y="#{s[46]}" font-family="#{FONT}" font-size="#{s[10]}" fill="#c9d1d9">#{esc(desc)}</text>)
        <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg" width="#{w}" height="#{h}" viewBox="0 0 #{w} #{h}" role="img" aria-label="#{esc(label)}">
            <rect x=".5" y=".5" width="#{w - 1}" height="#{h - 1}" rx="6" fill="#0d1117" stroke="#30363d"/>
            <text x="#{s[14]}" y="#{s[18]}" font-family="#{FONT}" font-size="#{s[14]}" font-weight="700" fill="#f0f6fc">#{esc(sponsor.name)}</text>
            <text x="#{s[14]}" y="#{s[32]}" font-family="#{FONT}" font-size="#{s[10]}" fill="#8b949e">#{esc(since)}</text>#{extra}
          </svg>
        SVG
      end

      def esc(text)
        CGI.escapeHTML(text.to_s)
      end
    end
  end
end
