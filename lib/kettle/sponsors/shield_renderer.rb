# frozen_string_literal: true

require "cgi"

module Kettle
  module Sponsors
    # Renders compact, single-line Shields.io-style SVG badges for a README
    # badge parade without making any network calls to shields.io.
    #
    # Supports all five canonical Shields.io styles:
    # +flat+, +flat-square+, +plastic+, +for-the-badge+, and +social+.
    module ShieldRenderer
      SHIELD_FONT = "Verdana,Geneva,DejaVu Sans,sans-serif"

      module_function

      # @param sponsor [Sponsor]
      # @param style [String, nil] overrides +theme.shield_style+
      # @param theme [Theme]
      # @param logo_uri [String, nil] pre-resolved +data:+ URI for the sponsor logo
      # @param base_dir [String, nil] base directory for resolving local logo paths
      # @param _options [Hash] forward-compatible options
      # @return [String] deterministic SVG markup
      def svg(sponsor, style: nil, theme: Theme.new, logo_uri: nil, base_dir: nil, **_options)
        st = (style || theme.shield_style).to_s
        raise Error, "unknown shield_style #{st.inspect}" unless Theme::SHIELD_STYLES.include?(st)

        resolved_logo = logo_uri || LogoLoader.resolve(
          sponsor.logo,
          base_dir: base_dir,
          fetch: theme.fetch_logos?,
          cache_dir: theme.logo_cache
        )
        label_text = sponsor.label || Icons.shield_label(sponsor.kind)
        msg_text = sponsor.name
        label_color = theme.label_color
        right_color = sponsor.color || theme.color || theme.accent_for(sponsor.kind)
        logo_bg = sponsor.logo_background || theme.logo_background

        font_css, font_stack = resolve_font(theme, (st == "for-the-badge") ? "#{label_text.upcase}#{msg_text.upcase}" : "#{label_text}#{msg_text}")

        case st
        when "for-the-badge"
          render_for_the_badge(label_text, msg_text, label_color, right_color, resolved_logo, logo_bg, font_css, font_stack)
        when "social"
          render_social(label_text, msg_text, resolved_logo, logo_bg, font_css, font_stack)
        when "plastic"
          render_standard(label_text, msg_text, label_color, right_color, resolved_logo, logo_bg, font_css, font_stack, height: 18, rx: 4, gradient: :plastic)
        when "flat-square"
          render_standard(label_text, msg_text, label_color, right_color, resolved_logo, logo_bg, font_css, font_stack, height: 20, rx: 0, gradient: :none)
        else
          render_standard(label_text, msg_text, label_color, right_color, resolved_logo, logo_bg, font_css, font_stack, height: 20, rx: 3, gradient: :flat)
        end
      end

      def resolve_font(theme, text)
        return ["", SHIELD_FONT] unless theme.font_file

        embedded = FontSubsetter.css_for(font_file: theme.font_file, text: text, family: theme.font_family)
        [embedded[:css], "'#{embedded[:family]}',#{SHIELD_FONT}"]
      end

      def text_width(text, char_px:)
        (text.to_s.length * char_px).ceil
      end

      def logo_block(uri, x:, y:, size:, rx:, bg:)
        return "" unless uri

        bg_rect = if bg.empty? || %w[none transparent].include?(bg.downcase)
          ""
        else
          %(<rect x="#{x}" y="#{y}" width="#{size}" height="#{size}" rx="#{rx}" fill="#{esc(bg)}"/>)
        end
        pad = (size * 0.12).round(1)
        inner = (size - (pad * 2)).round(1)
        %(#{bg_rect}<image x="#{(x + pad).round(1)}" y="#{(y + pad).round(1)}" width="#{inner}" height="#{inner}" href="#{esc(uri)}" preserveAspectRatio="xMidYMid meet"/>)
      end

      def render_standard(label, msg, label_color, right_color, logo_uri, logo_bg, font_css, font_stack, height:, rx:, gradient:)
        logo_size = height - 6
        logo_pad = logo_uri ? logo_size + 6 : 0
        lw = text_width(label, char_px: 6.4) + 12 + logo_pad
        rw = text_width(msg, char_px: 6.4) + 12
        total = lw + rw
        lx = logo_pad + ((lw - logo_pad) / 2.0)
        rx_pos = lw + (rw / 2.0)
        ty = (height == 18) ? 12.5 : 14
        tsy = ty + 1
        aria = "#{label}: #{msg}"

        grad_def, grad_rect = standard_gradient(gradient, total, height)
        style_tag = font_css.empty? ? "" : "<style>#{font_css}</style>"
        logo_el = logo_block(logo_uri, x: 4, y: 3, size: logo_size, rx: 2, bg: logo_bg)

        <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg" width="#{total}" height="#{height}" viewBox="0 0 #{total} #{height}" role="img" aria-label="#{esc(aria)}">
            <title>#{esc(aria)}</title>
            #{style_tag}#{grad_def}<clipPath id="ks-sh-r"><rect width="#{total}" height="#{height}" rx="#{rx}" fill="#fff"/></clipPath>
            <g clip-path="url(#ks-sh-r)">
              <rect width="#{lw}" height="#{height}" fill="#{esc(label_color)}"/>
              <rect x="#{lw}" width="#{rw}" height="#{height}" fill="#{esc(right_color)}"/>
              #{grad_rect}
            </g>
            #{logo_el}<g fill="#fff" text-anchor="middle" font-family="#{esc(font_stack)}" font-size="11">
              <text x="#{fmt(lx)}" y="#{tsy}" fill="#010101" fill-opacity=".3">#{esc(label)}</text>
              <text x="#{fmt(lx)}" y="#{ty}">#{esc(label)}</text>
              <text x="#{fmt(rx_pos)}" y="#{tsy}" fill="#010101" fill-opacity=".3">#{esc(msg)}</text>
              <text x="#{fmt(rx_pos)}" y="#{ty}">#{esc(msg)}</text>
            </g>
          </svg>
        SVG
      end

      def standard_gradient(gradient, total, height)
        case gradient
        when :flat
          [
            '<linearGradient id="ks-sh-s" x2="0" y2="100%"><stop offset="0" stop-color="#bbb" stop-opacity=".1"/><stop offset="1" stop-opacity=".1"/></linearGradient>',
            %(<rect width="#{total}" height="#{height}" fill="url(#ks-sh-s)"/>)
          ]
        when :plastic
          [
            '<linearGradient id="ks-sh-p" x2="0" y2="100%"><stop offset="0" stop-color="#fff" stop-opacity=".7"/><stop offset=".1" stop-color="#aaa" stop-opacity=".1"/><stop offset=".9" stop-opacity=".3"/><stop offset="1" stop-opacity=".5"/></linearGradient>',
            %(<rect width="#{total}" height="#{height}" fill="url(#ks-sh-p)"/>)
          ]
        else
          ["", ""]
        end
      end

      def render_for_the_badge(label, msg, label_color, right_color, logo_uri, logo_bg, font_css, font_stack)
        up_label = label.upcase
        up_msg = msg.upcase
        height = 28
        logo_size = 18
        logo_pad = logo_uri ? logo_size + 8 : 0
        lw = text_width(up_label, char_px: 7.4) + 18 + logo_pad
        rw = text_width(up_msg, char_px: 7.8) + 18
        total = lw + rw
        lx = logo_pad + ((lw - logo_pad) / 2.0)
        rx_pos = lw + (rw / 2.0)
        aria = "#{label}: #{msg}"
        style_tag = font_css.empty? ? "" : "<style>#{font_css}</style>"
        logo_el = logo_block(logo_uri, x: 6, y: 5, size: logo_size, rx: 3, bg: logo_bg)

        <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg" width="#{total}" height="#{height}" viewBox="0 0 #{total} #{height}" role="img" aria-label="#{esc(aria)}">
            <title>#{esc(aria)}</title>
            #{style_tag}<g shape-rendering="crispEdges">
              <rect width="#{lw}" height="#{height}" fill="#{esc(label_color)}"/>
              <rect x="#{lw}" width="#{rw}" height="#{height}" fill="#{esc(right_color)}"/>
            </g>
            #{logo_el}<g fill="#fff" text-anchor="middle" font-family="#{esc(font_stack)}" font-size="10" letter-spacing="0.8">
              <text x="#{fmt(lx)}" y="17.5">#{esc(up_label)}</text>
              <text x="#{fmt(rx_pos)}" y="17.5" font-weight="bold">#{esc(up_msg)}</text>
            </g>
          </svg>
        SVG
      end

      def render_social(label, msg, logo_uri, logo_bg, font_css, font_stack)
        height = 20
        logo_size = 14
        logo_pad = logo_uri ? logo_size + 6 : 0
        lw = text_width(label, char_px: 6.8) + 12 + logo_pad
        rw = text_width(msg, char_px: 6.4) + 12
        gap = 6
        total = lw + gap + rw
        lx = logo_pad + ((lw - logo_pad) / 2.0)
        rx_pos = lw + gap + (rw / 2.0)
        aria = "#{label}: #{msg}"
        style_tag = font_css.empty? ? "" : "<style>#{font_css}</style>"
        logo_el = logo_block(logo_uri, x: 4, y: 3, size: logo_size, rx: 2, bg: logo_bg)

        <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg" width="#{total}" height="#{height}" viewBox="0 0 #{total} #{height}" role="img" aria-label="#{esc(aria)}">
            <title>#{esc(aria)}</title>
            #{style_tag}<linearGradient id="ks-sh-soc" x2="0" y2="100%"><stop offset="0" stop-color="#fcfcfc"/><stop offset="1" stop-color="#eee"/></linearGradient>
            <rect x=".5" y=".5" width="#{lw - 1}" height="#{height - 1}" rx="3" fill="url(#ks-sh-soc)" stroke="#d5d5d5"/>
            <rect x="#{lw + gap - 0.5}" y=".5" width="#{rw - 1}" height="#{height - 1}" rx="3" fill="#fff" stroke="#d5d5d5"/>
            <path d="M#{lw + gap} 6.5L#{lw + 2} 10L#{lw + gap} 13.5" fill="#fff" stroke="#d5d5d5"/>
            #{logo_el}<g fill="#333" text-anchor="middle" font-family="#{esc(font_stack)}" font-size="11">
              <text x="#{fmt(lx)}" y="14" font-weight="bold">#{esc(label)}</text>
              <text x="#{fmt(rx_pos)}" y="14">#{esc(msg)}</text>
            </g>
          </svg>
        SVG
      end

      def fmt(num)
        num.round(1).to_s.sub(/\.0\z/, "")
      end

      def esc(text)
        CGI.escapeHTML(text.to_s)
      end
    end
  end
end
