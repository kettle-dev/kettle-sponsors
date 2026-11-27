# frozen_string_literal: true

require "cgi"

module Kettle
  module Sponsors
    # Deterministic SVG renderer for one sponsor. Same input always yields the
    # same bytes.
    #
    # Uses a hybrid layout across variants:
    # - +:desktop+: optional left logo tile, inline kind icon + label on the
    #   metadata line, optional description, and optional kind animation motif.
    # - +:phone+: compact 0.8x card with optional left logo tile and a top-right
    #   icon-only corner pill, truncating descriptions at 40 characters.
    # - +:shield+: compact single-line Shields.io-style badge (delegated to
    #   {ShieldRenderer}).
    module BadgeRenderer
      VARIANTS = %i[desktop phone shield].freeze
      FONT = Theme::DEFAULT_FONT

      module_function

      # @param sponsor [Sponsor]
      # @param variant [Symbol] +:desktop+, +:phone+, or +:shield+
      # @param theme [Theme]
      # @param logo_uri [String, nil] pre-resolved +data:+ URI for the sponsor logo
      # @param base_dir [String, nil] directory for resolving local logo paths
      # @param options [Hash] extra forward-compatible keyword arguments
      # @return [String] SVG document
      def svg(sponsor, variant: :desktop, theme: Theme.new, logo_uri: nil, base_dir: nil, **options)
        raise ArgumentError, "unknown variant #{variant.inspect}" unless VARIANTS.include?(variant)
        return ShieldRenderer.svg(sponsor, theme: theme, logo_uri: logo_uri, base_dir: base_dir, **options) if variant == :shield

        resolved_logo = logo_uri || LogoLoader.resolve(
          sponsor.logo,
          base_dir: base_dir,
          fetch: theme.fetch_logos?,
          cache_dir: theme.logo_cache
        )
        if variant == :phone
          render_phone(sponsor, theme: theme, logo_uri: resolved_logo)
        else
          render_desktop(sponsor, theme: theme, logo_uri: resolved_logo)
        end
      end

      def render_desktop(sponsor, theme:, logo_uri:)
        since = since_text(sponsor)
        kind_label = Icons.label(sponsor.kind)
        meta = "#{kind_label} · #{since}"
        desc = sponsor.description
        accent = theme.accent_for(sponsor.kind)

        tx = logo_uri ? 58 : 14
        motif_pad = theme.animated? ? Animations::MOTIF_WIDTH : 0
        text_w = [
          (sponsor.name.length * 9) + 18,
          (meta.length * 6.2).ceil + 24,
          (desc.length * 6.1).ceil + 14
        ].max
        w = [210, tx + text_w + 14 + motif_pad].max
        h = desc.empty? ? 52 : 64

        font_css, font_stack = resolve_font(theme, "#{sponsor.name}#{meta}#{desc}")
        anim = Animations.build(sponsor.kind, width: w, height: h, theme: theme)
        style_body = [font_css, anim[:css]].reject(&:empty?).join("\n")
        defs_tag = anim[:defs].empty? ? "" : "\n  <defs>#{anim[:defs]}</defs>"
        style_tag = style_body.empty? ? "" : "\n  <style>#{style_body}</style>"
        motif_tag = anim[:body].empty? ? "" : "\n  #{anim[:body]}"

        logo_tag = desktop_logo_tag(sponsor, theme, logo_uri, h)
        desc_tag = desc.empty? ? "" : %(\n  <text x="#{tx}" y="52" font-family="#{esc(font_stack)}" font-size="10.5" fill="#{esc(theme.description)}">#{esc(desc)}</text>)
        label = [sponsor.name, kind_label, since, desc].reject(&:empty?).join(", ")

        <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg" width="#{w}" height="#{h}" viewBox="0 0 #{w} #{h}" role="img" aria-label="#{esc(label)}">#{defs_tag}#{style_tag}
            <rect x=".5" y=".5" width="#{w - 1}" height="#{h - 1}" rx="6" fill="#{esc(theme.background)}" stroke="#{esc(theme.border)}"/>#{motif_tag}#{logo_tag}
            <text x="#{tx}" y="21" font-family="#{esc(font_stack)}" font-size="14" font-weight="700" fill="#{esc(theme.text)}">#{esc(sponsor.name)}</text>
            <g transform="translate(#{tx},26.5)">#{Icons.svg(sponsor.kind, color: accent)}</g>
            <text x="#{tx + 16}" y="36" font-family="#{esc(font_stack)}" font-size="10.5" fill="#{esc(theme.muted)}">#{esc(meta)}</text>#{desc_tag}
          </svg>
        SVG
      end

      def render_phone(sponsor, theme:, logo_uri:)
        since = since_text(sponsor)
        kind_label = Icons.label(sponsor.kind)
        desc = sponsor.description
        desc = "#{desc[0, 40]}…" if desc.length > 40
        accent = theme.accent_for(sponsor.kind)

        tx = logo_uri ? 44 : 11
        pill_pad = 26
        text_w = [
          (sponsor.name.length * 7.2).ceil + pill_pad,
          (since.length * 5.2).ceil + pill_pad,
          (desc.length * 5.0).ceil + 10
        ].max
        w = [164, tx + text_w + 10].max
        h = desc.empty? ? 40 : 48

        font_css, font_stack = resolve_font(theme, "#{sponsor.name}#{since}#{desc}")
        style_tag = font_css.empty? ? "" : "\n  <style>#{font_css}</style>"
        logo_tag = phone_logo_tag(sponsor, theme, logo_uri, h)
        desc_tag = desc.empty? ? "" : %(\n  <text x="#{tx}" y="40" font-family="#{esc(font_stack)}" font-size="8.5" fill="#{esc(theme.description)}">#{esc(desc)}</text>)
        label = [sponsor.name, kind_label, since, desc].reject(&:empty?).join(", ")

        <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg" width="#{w}" height="#{h}" viewBox="0 0 #{w} #{h}" role="img" aria-label="#{esc(label)}">#{style_tag}
            <rect x=".5" y=".5" width="#{w - 1}" height="#{h - 1}" rx="5" fill="#{esc(theme.background)}" stroke="#{esc(theme.border)}"/>#{logo_tag}
            <rect x="#{w - 22}" y="6" width="16" height="16" rx="4" fill="#{esc(theme.background)}" stroke="#{esc(theme.border)}" stroke-width="0.8"/>
            <g transform="translate(#{w - 19},9) scale(0.83)">#{Icons.svg(sponsor.kind, color: accent)}</g>
            <text x="#{tx}" y="17" font-family="#{esc(font_stack)}" font-size="11.5" font-weight="700" fill="#{esc(theme.text)}">#{esc(sponsor.name)}</text>
            <text x="#{tx}" y="29" font-family="#{esc(font_stack)}" font-size="8.5" fill="#{esc(theme.muted)}">#{esc(since)}</text>#{desc_tag}
          </svg>
        SVG
      end

      def desktop_logo_tag(sponsor, theme, logo_uri, height)
        return "" unless logo_uri

        size = 36
        ly = ((height - size) / 2.0).round
        bg = sponsor.logo_background || theme.logo_background
        bg_el = transparent_bg?(bg) ? "" : %(\n  <rect x="11" y="#{ly}" width="#{size}" height="#{size}" rx="7" fill="#{esc(bg)}"/>)
        %(#{bg_el}\n  <image x="15" y="#{ly + 4}" width="#{size - 8}" height="#{size - 8}" href="#{esc(logo_uri)}" preserveAspectRatio="xMidYMid meet"/>)
      end

      def phone_logo_tag(sponsor, theme, logo_uri, height)
        return "" unless logo_uri

        size = 28
        ly = ((height - size) / 2.0).round
        bg = sponsor.logo_background || theme.logo_background
        bg_el = transparent_bg?(bg) ? "" : %(\n  <rect x="8" y="#{ly}" width="#{size}" height="#{size}" rx="6" fill="#{esc(bg)}"/>)
        %(#{bg_el}\n  <image x="11" y="#{ly + 3}" width="#{size - 6}" height="#{size - 6}" href="#{esc(logo_uri)}" preserveAspectRatio="xMidYMid meet"/>)
      end

      def transparent_bg?(bg)
        bg.to_s.strip.empty? || %w[none transparent].include?(bg.to_s.strip.downcase)
      end

      def since_text(sponsor)
        sponsor.since ? "since #{sponsor.since.iso8601[0, 7]}" : "sponsor"
      end

      def resolve_font(theme, text)
        return ["", theme.font] unless theme.font_file

        embedded = FontSubsetter.css_for(font_file: theme.font_file, text: text, family: theme.font_family)
        [embedded[:css], "'#{embedded[:family]}',#{theme.font}"]
      end

      def esc(text)
        CGI.escapeHTML(text.to_s)
      end
    end
  end
end
