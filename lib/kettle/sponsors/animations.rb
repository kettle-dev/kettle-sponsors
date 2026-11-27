# frozen_string_literal: true

require "cgi"

module Kettle
  module Sponsors
    # Kind-specific SVG background motifs and CSS animations for desktop badges.
    #
    # Supports +animate: "hover"+ (triggers on +svg:hover+, ideal for inline/object
    # web embeds) and +animate: "always"+ (subtle continuous loop that also plays
    # inside GitHub README +<img>+ tags). Always honors +prefers-reduced-motion+.
    module Animations
      NGLOW = '<filter id="nglow" x="-35%" y="-60%" width="170%" height="220%">' \
        '<feGaussianBlur in="SourceGraphic" stdDeviation="1.1" result="a"/>' \
        '<feGaussianBlur in="SourceGraphic" stdDeviation="2.8" result="b"/>' \
        '<feMerge><feMergeNode in="b"/><feMergeNode in="a"/><feMergeNode in="SourceGraphic"/></feMerge>' \
        "</filter>"

      # Reserved width on the right side of the card when a motif is active.
      MOTIF_WIDTH = 96

      module_function

      # Build +{defs:, css:, body:}+ for +kind+ inside a card of size +width+ x +height+.
      #
      # @param kind [String] one of Sponsor::KINDS
      # @param width [Integer] badge width
      # @param height [Integer] badge height
      # @param theme [Theme]
      # @param _options [Hash] forward-compatible options
      # @return [Hash{Symbol => String}]
      def build(kind, width:, height:, theme:, **_options)
        return {defs: "", css: "", body: ""} unless theme.animated?

        case kind.to_s
        when "compute" then compute_motif(width, height, theme)
        when "time" then time_motif(width, height, theme)
        when "services" then services_motif(width, height, theme)
        else financial_motif(width, height, theme)
        end
      end

      def financial_motif(width, height, theme)
        pal = theme.coin_palette
        sel = trigger_prefix(theme)
        defs = <<~DEFS.chomp
          #{NGLOW}
          <clipPath id="ks-win"><rect x="#{width - 94}" y="2" width="92" height="#{height - 4}" rx="4"/></clipPath>
          <linearGradient id="ks-coin-face" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stop-color="#{esc(pal[:face_light])}"/>
            <stop offset="55%" stop-color="#{esc(pal[:face_mid])}"/>
            <stop offset="100%" stop-color="#{esc(pal[:face_dark])}"/>
          </linearGradient>
          <linearGradient id="ks-coin-rim" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stop-color="#{esc(pal[:rim_dark])}"/>
            <stop offset="30%" stop-color="#{esc(pal[:rim_light])}"/>
            <stop offset="65%" stop-color="#{esc(pal[:face_light])}"/>
            <stop offset="100%" stop-color="#{esc(pal[:rim_dark])}"/>
          </linearGradient>
        DEFS

        css = <<~CSS.chomp
          .ks-drop{opacity:0;transform:translateY(-28px)}
          #{sel} .ks-d1{animation:ks-fall 2.6s cubic-bezier(.32,0,.67,.95) infinite}
          #{sel} .ks-d2{animation:ks-fall 2.6s cubic-bezier(.32,0,.67,.95) .85s infinite}
          #{sel} .ks-d3{animation:ks-fall 2.6s cubic-bezier(.32,0,.67,.95) 1.7s infinite}
          @keyframes ks-fall{0%{opacity:0;transform:translateY(-26px)}14%{opacity:1}58%{opacity:1;transform:translateY(0)}74%{opacity:1;transform:translateY(-2px)}86%{opacity:1;transform:translateY(0)}100%{opacity:0;transform:translateY(0)}}
          @media (prefers-reduced-motion:reduce){.ks-drop{animation:none!important;opacity:0}}
        CSS

        floor_y = height - 6
        horizon_y = height - 22
        x0 = width - 92
        x1 = width - 6
        body = <<~SVG.chomp
          <g clip-path="url(#ks-win)">
            <g stroke="#{esc(pal[:stroke])}" stroke-width="0.6" opacity="0.28">
              <line x1="#{x0 + 12}" y1="#{horizon_y}" x2="#{x1 - 4}" y2="#{horizon_y}"/>
              <line x1="#{x0 + 6}" y1="#{horizon_y + 7}" x2="#{x1 - 2}" y2="#{horizon_y + 7}"/>
              <line x1="#{x0}" y1="#{floor_y}" x2="#{x1}" y2="#{floor_y}"/>
              <line x1="#{x0 + 18}" y1="#{horizon_y}" x2="#{x0 + 6}" y2="#{floor_y}"/>
              <line x1="#{x0 + 48}" y1="#{horizon_y}" x2="#{x0 + 44}" y2="#{floor_y}"/>
              <line x1="#{x0 + 74}" y1="#{horizon_y}" x2="#{x1 - 4}" y2="#{floor_y}"/>
            </g>
            #{coin_3d(width - 58, floor_y - 10, 7.5, 2.5, 3.0, pal)}
            #{coin_3d(width - 58, floor_y - 13.5, 7.5, 2.5, 3.0, pal)}
            #{coin_3d(width - 30, floor_y - 4, 10.0, 3.2, 3.8, pal)}
            #{coin_3d(width - 30, floor_y - 8.2, 10.0, 3.2, 3.8, pal)}
            #{coin_3d(width - 30, floor_y - 12.4, 10.0, 3.2, 3.8, pal)}
            #{coin_3d(width - 47, floor_y - 4, 9.0, 2.9, 3.4, pal)}
            <g class="ks-drop ks-d1">#{coin_3d(width - 30, floor_y - 16.6, 10.0, 3.2, 3.8, pal, glow: true)}</g>
            <g class="ks-drop ks-d2">#{coin_3d(width - 58, floor_y - 17.0, 7.5, 2.5, 3.0, pal, glow: true)}</g>
            <g class="ks-drop ks-d3">#{coin_3d(width - 47, floor_y - 7.8, 9.0, 2.9, 3.4, pal, glow: true)}</g>
          </g>
        SVG

        {defs: defs, css: css, body: body}
      end

      def compute_motif(width, height, theme)
        accent = esc(theme.accent_for("compute"))
        sel = trigger_prefix(theme)
        mid = (height * 0.58).round
        x0 = width - 92
        pts = [
          [x0, mid], [x0 + 16, mid], [x0 + 22, mid - 5], [x0 + 27, mid + 6],
          [x0 + 34, mid - 20], [x0 + 41, mid + 12], [x0 + 47, mid - 4],
          [x0 + 53, mid], [width - 8, mid]
        ]
        path_d = "M" + pts.map { |px, py| "#{px} #{py}" }.join(" L")

        css = <<~CSS.chomp
          .ks-ecg-pulse{stroke-dasharray:34 150;stroke-dashoffset:184;opacity:0;transition:opacity .35s ease-out}
          .ks-ecg-dot{opacity:0;transition:opacity .35s ease-out}
          #{sel} .ks-ecg-pulse{opacity:1;animation:ks-ecg 1.8s linear infinite}
          #{sel} .ks-ecg-dot{opacity:1;animation:ks-dot 1.8s ease-in-out infinite}
          @keyframes ks-ecg{0%{stroke-dashoffset:184}100%{stroke-dashoffset:0}}
          @keyframes ks-dot{0%,100%{opacity:.25;r:1.5}45%{opacity:1;r:2.6}}
          @media (prefers-reduced-motion:reduce){.ks-ecg-pulse,.ks-ecg-dot{animation:none!important;opacity:0}}
        CSS

        body = <<~SVG.chomp
          <g>
            <path d="#{path_d}" fill="none" stroke="#{accent}" stroke-width="1.2" opacity="0.35" stroke-linejoin="round" stroke-linecap="round"/>
            <path class="ks-ecg-pulse" d="#{path_d}" fill="none" stroke="#{accent}" stroke-width="1.8" stroke-linejoin="round" stroke-linecap="round" filter="url(#nglow)"/>
            <circle class="ks-ecg-dot" cx="#{x0 + 34}" cy="#{mid - 20}" r="2" fill="#{accent}" filter="url(#nglow)"/>
          </g>
        SVG

        {defs: NGLOW, css: css, body: body}
      end

      def time_motif(width, height, theme)
        accent = esc(theme.accent_for("time"))
        sel = trigger_prefix(theme)
        # Prime-staggered durations and delays simulate organic slow random typing
        # with a bright strike and smooth residual glow decay.
        active_keys = {
          [0, 1] => ["2.3s", "-0.2s"],
          [0, 4] => ["3.7s", "0.9s"],
          [1, 0] => ["4.1s", "0.4s"],
          [1, 2] => ["2.9s", "-0.75s"],
          [1, 5] => ["5.3s", "1.4s"],
          [2, 1] => ["3.1s", "1.8s"],
          [2, 3] => ["4.7s", "0.6s"],
          [2, 4] => ["5.9s", "2.3s"]
        }

        css_rules = [
          ".ks-key-lit{opacity:0;transition:opacity .65s ease-out}",
          "@keyframes ks-type{0%,100%{opacity:0}6%{opacity:.95}24%{opacity:.45}42%{opacity:.12}56%{opacity:0}}",
          "@media (prefers-reduced-motion:reduce){.ks-key-lit{animation:none!important;opacity:0}}"
        ]

        y_start = [12, ((height - 34) / 2.0).round].max
        base_keys = []
        lit_keys = []
        idx = 0
        3.times do |row|
          6.times do |col|
            kx = width - 88 + (col * 12) + (row * 3)
            ky = y_start + (row * 11)
            base_keys << %(<rect x="#{kx}" y="#{ky}" width="9.5" height="8" rx="1.5" fill="#{esc(theme.background)}" stroke="#{esc(theme.border)}" stroke-width="0.7" opacity="0.8"/>)
            timing = active_keys[[row, col]]
            next unless timing

            idx += 1
            dur, delay = timing
            css_rules << "#{sel} .ks-k#{idx}{animation:ks-type #{dur} ease-out #{delay} infinite}"
            lit_keys << %(<rect class="ks-key-lit ks-k#{idx}" x="#{kx}" y="#{ky}" width="9.5" height="8" rx="1.5" fill="#{accent}" stroke="#{accent}" stroke-width="0.6" filter="url(#nglow)"/>)
          end
        end

        body = "<g>#{base_keys.join}#{lit_keys.join}</g>"
        {defs: NGLOW, css: css_rules.join("\n"), body: body}
      end

      def services_motif(width, height, theme)
        accent = esc(theme.accent_for("services"))
        sel = trigger_prefix(theme)
        cx1 = width - 40
        cy1 = (height * 0.44).round
        cx2 = width - 20
        cy2 = (height * 0.68).round

        css = <<~CSS.chomp
          .ks-gear1,.ks-gear2{transform-box:fill-box;transform-origin:center}
          #{sel} .ks-gear1{animation:ks-cw 6s linear infinite}
          #{sel} .ks-gear2{animation:ks-ccw 4.5s linear infinite}
          @keyframes ks-cw{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}
          @keyframes ks-ccw{from{transform:rotate(0deg)}to{transform:rotate(-360deg)}}
          @media (prefers-reduced-motion:reduce){.ks-gear1,.ks-gear2{animation:none!important}}
        CSS

        g1 = gear_path(cx1, cy1, outer: 12.5, inner: 9.2, hole: 4.0, teeth: 8)
        g2 = gear_path(cx2, cy2, outer: 8.8, inner: 6.3, hole: 2.6, teeth: 6)

        body = <<~SVG.chomp
          <g opacity="0.65" filter="url(#nglow)">
            <g class="ks-gear1">#{g1.sub("__COLOR__", accent)}</g>
            <g class="ks-gear2">#{g2.sub("__COLOR__", accent)}</g>
          </g>
        SVG

        {defs: NGLOW, css: css, body: body}
      end

      def trigger_prefix(theme)
        (theme.animate == "always") ? "svg" : "svg:hover"
      end

      # Render a single 3D metallic coin (extruded cylinder edge + top ellipse + inner rim).
      def coin_3d(cx, cy, rx, ry, thickness, pal, glow: false)
        x_l = format("%.1f", cx - rx)
        x_r = format("%.1f", cx + rx)
        y_t = format("%.1f", cy)
        y_b = format("%.1f", cy + thickness)
        rx_s = format("%.1f", rx)
        ry_s = format("%.1f", ry)
        irx = format("%.1f", rx * 0.68)
        iry = format("%.1f", ry * 0.62)
        flt = glow ? ' filter="url(#nglow)"' : ""
        # Extruded milled cylinder wall + top metallic face + embossed inner ring + glint
        %(<g#{flt}>) +
          %(<path d="M#{x_l} #{y_t} L#{x_l} #{y_b} A#{rx_s} #{ry_s} 0 0 0 #{x_r} #{y_b} L#{x_r} #{y_t} Z" fill="url(#ks-coin-rim)" stroke="#{esc(pal[:stroke])}" stroke-width="0.55"/>) +
          %(<ellipse cx="#{format("%.1f", cx)}" cy="#{y_t}" rx="#{rx_s}" ry="#{ry_s}" fill="url(#ks-coin-face)" stroke="#{esc(pal[:stroke])}" stroke-width="0.55"/>) +
          %(<ellipse cx="#{format("%.1f", cx)}" cy="#{y_t}" rx="#{irx}" ry="#{iry}" fill="none" stroke="#{esc(pal[:rim_dark])}" stroke-width="0.45" opacity="0.65"/>) +
          "</g>"
      end

      # Compute a crisp toothed gear polygon + center hub circle.
      def gear_path(cx, cy, outer:, inner:, hole:, teeth:)
        pts = []
        step = (2.0 * Math::PI) / teeth
        teeth.times do |i|
          a0 = i * step
          [
            [inner, a0],
            [outer, a0 + (step * 0.18)],
            [outer, a0 + (step * 0.48)],
            [inner, a0 + (step * 0.66)]
          ].each do |r, ang|
            pts << format("%.1f,%.1f", cx + (r * Math.cos(ang)), cy + (r * Math.sin(ang)))
          end
        end
        %(<polygon points="#{pts.join(" ")}" fill="none" stroke="__COLOR__" stroke-width="1.25" stroke-linejoin="round"/>) +
          %(<circle cx="#{cx}" cy="#{cy}" r="#{hole}" fill="none" stroke="__COLOR__" stroke-width="1.1"/>)
      end

      def esc(text)
        CGI.escapeHTML(text.to_s)
      end
    end
  end
end
