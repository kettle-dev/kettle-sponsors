# frozen_string_literal: true

module Kettle
  module Sponsors
    # Visual and rendering configuration for sponsor badges.
    #
    # Controls card colors, logo tile backdrop, kind accents, coin metal style,
    # font stack and optional subsetted font embedding, animation mode,
    # Shields.io-compatible small badge style, and offline vs. remote logo loading.
    class Theme
      DEFAULT_FONT = "system-ui,-apple-system,'Segoe UI',Roboto,sans-serif"
      ANIMATE_MODES = %w[none hover always].freeze
      SHIELD_STYLES = %w[flat flat-square plastic for-the-badge social].freeze
      COIN_METALS = %w[gold silver].freeze

      DEFAULT_ACCENTS = {
        "financial" => "#3fb950",
        "compute" => "#58a6ff",
        "time" => "#d2a8ff",
        "services" => "#f0883e"
      }.freeze

      COIN_PALETTES = {
        "gold" => {
          face_light: "#ffe58f",
          face_mid: "#f5c542",
          face_dark: "#c99612",
          rim_light: "#e6b422",
          rim_dark: "#8c6200",
          stroke: "#a67604"
        }.freeze,
        "silver" => {
          face_light: "#f0f6fc",
          face_mid: "#d0d7de",
          face_dark: "#8b949e",
          rim_light: "#b1bac4",
          rim_dark: "#57606a",
          stroke: "#6e7681"
        }.freeze
      }.freeze

      attr_reader :background, :border, :text, :muted, :description,
        :logo_background, :accents, :coin_metal, :label_color, :color,
        :font, :font_file, :font_family, :animate, :shield_style,
        :fetch_logos, :logo_cache

      # Build a Theme from a YAML-loaded Hash.
      #
      # @param hash [Hash, nil] theme configuration mapping
      # @return [Theme]
      def self.from_h(hash = nil)
        h = hash.is_a?(Hash) ? hash : {}
        new(
          background: h["background"],
          border: h["border"],
          text: h["text"],
          muted: h["muted"],
          description: h["description"],
          logo_background: h["logo_background"],
          accents: h["accents"],
          coin_metal: h["coin_metal"],
          label_color: h["label_color"],
          color: h["color"],
          font: h["font"],
          font_file: h["font_file"],
          font_family: h["font_family"],
          animate: h["animate"],
          shield_style: h["shield_style"],
          fetch_logos: h["fetch_logos"],
          logo_cache: h["logo_cache"]
        )
      end

      def initialize(
        background: nil,
        border: nil,
        text: nil,
        muted: nil,
        description: nil,
        logo_background: nil,
        accents: nil,
        coin_metal: nil,
        label_color: nil,
        color: nil,
        font: nil,
        font_file: nil,
        font_family: nil,
        animate: nil,
        shield_style: nil,
        fetch_logos: nil,
        logo_cache: nil,
        **_options
      )
        @background = (background || "#0d1117").to_s
        @border = (border || "#30363d").to_s
        @text = (text || "#f0f6fc").to_s
        @muted = (muted || "#8b949e").to_s
        @description = (description || "#c9d1d9").to_s
        @logo_background = (logo_background.nil? ? "#ffffff" : logo_background).to_s
        @accents = normalize_accents(accents)
        @coin_metal = (coin_metal || "gold").to_s
        raise Error, "unknown coin_metal #{@coin_metal.inspect}" unless COIN_METALS.include?(@coin_metal)

        @label_color = (label_color || "#555555").to_s
        @color = normalize_optional(color)
        @font = (font || DEFAULT_FONT).to_s
        @font_file = normalize_optional(font_file)
        @font_family = normalize_optional(font_family)
        @animate = (animate || "none").to_s
        raise Error, "unknown animate mode #{@animate.inspect}" unless ANIMATE_MODES.include?(@animate)

        @shield_style = (shield_style || "flat").to_s
        raise Error, "unknown shield_style #{@shield_style.inspect}" unless SHIELD_STYLES.include?(@shield_style)

        @fetch_logos = fetch_logos == true
        @logo_cache = normalize_optional(logo_cache)
      end

      # @param kind [String] sponsor kind
      # @return [String] hex/CSS accent color for the kind
      def accent_for(kind)
        accents.fetch(kind.to_s, DEFAULT_ACCENTS.fetch("financial"))
      end

      # @return [Hash{Symbol => String}] coin gradient palette for +coin_metal+
      def coin_palette
        COIN_PALETTES.fetch(coin_metal)
      end

      # @return [Boolean] true when animations are enabled
      def animated?
        animate != "none"
      end

      # @return [Boolean] true when remote HTTP(S) logos may be fetched
      def fetch_logos?
        @fetch_logos
      end

      # Return a copy with selected attributes overridden.
      #
      # @param overrides [Hash] attributes to override
      # @return [Theme]
      def with(**overrides)
        self.class.new(
          background: overrides.fetch(:background, background),
          border: overrides.fetch(:border, border),
          text: overrides.fetch(:text, text),
          muted: overrides.fetch(:muted, muted),
          description: overrides.fetch(:description, description),
          logo_background: overrides.fetch(:logo_background, logo_background),
          accents: overrides.fetch(:accents, accents),
          coin_metal: overrides.fetch(:coin_metal, coin_metal),
          label_color: overrides.fetch(:label_color, label_color),
          color: overrides.fetch(:color, color),
          font: overrides.fetch(:font, font),
          font_file: overrides.fetch(:font_file, font_file),
          font_family: overrides.fetch(:font_family, font_family),
          animate: overrides.fetch(:animate, animate),
          shield_style: overrides.fetch(:shield_style, shield_style),
          fetch_logos: overrides.fetch(:fetch_logos, fetch_logos),
          logo_cache: overrides.fetch(:logo_cache, logo_cache)
        )
      end

      # Stable hash representation included in checksum computation.
      #
      # @return [Hash{String => Object}]
      def to_h
        {
          "background" => background,
          "border" => border,
          "text" => text,
          "muted" => muted,
          "description" => description,
          "logo_background" => logo_background,
          "accents" => accents,
          "coin_metal" => coin_metal,
          "label_color" => label_color,
          "color" => color,
          "font" => font,
          "font_file" => font_file,
          "font_family" => font_family,
          "animate" => animate,
          "shield_style" => shield_style,
          "fetch_logos" => fetch_logos,
          "logo_cache" => logo_cache
        }
      end

      private

      def normalize_accents(value)
        merged = DEFAULT_ACCENTS.dup
        if value.is_a?(Hash)
          value.each { |k, v| merged[k.to_s] = v.to_s unless v.nil? || v.to_s.strip.empty? }
        end
        merged.freeze
      end

      def normalize_optional(value)
        str = value.to_s.strip
        str.empty? ? nil : str
      end
    end
  end
end
