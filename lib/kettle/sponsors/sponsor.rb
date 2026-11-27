# frozen_string_literal: true

require "date"

module Kettle
  module Sponsors
    # One sponsor entry, normalized from a +corporate_sponsors+ hash.
    class Sponsor
      BADGE_MODES = %w[central local].freeze
      KINDS = %w[financial compute time services].freeze

      attr_reader :name, :href, :since, :until_date, :description, :badge,
        :kind, :logo, :label, :color, :logo_background

      def self.from_h(hash)
        new(
          name: hash["name"],
          href: hash["target_href"] || hash["url"],
          since: hash["since"],
          until_date: hash["until"],
          description: hash["description"],
          badge: hash["badge"],
          kind: hash["kind"],
          logo: hash["logo"] || hash["image_src"] || hash["img_src"],
          label: hash["label"],
          color: hash["color"],
          logo_background: hash["logo_background"]
        )
      end

      def initialize(
        name:,
        href: nil,
        since: nil,
        until_date: nil,
        description: nil,
        badge: nil,
        kind: nil,
        logo: nil,
        label: nil,
        color: nil,
        logo_background: nil,
        **_options
      )
        @name = name.to_s.strip
        raise Error, "sponsor requires a name" if @name.empty?

        @href = href.to_s.strip
        raise Error, "sponsor #{@name.inspect} has a non-http(s) link: #{@href.inspect}" unless @href.empty? || @href.match?(%r{\Ahttps?://}i)

        @since = parse_date(since)
        @until_date = parse_date(until_date)
        @description = description.to_s.strip
        @badge = (badge || "central").to_s
        raise Error, "sponsor #{@name.inspect} has unknown badge mode #{@badge.inspect}" unless BADGE_MODES.include?(@badge)

        @kind = (kind || "financial").to_s
        raise Error, "sponsor #{@name.inspect} has unknown kind #{@kind.inspect}" unless KINDS.include?(@kind)

        @logo = normalize_logo(logo)
        @label = normalize_optional(label)
        @color = normalize_optional(color)
        @logo_background = normalize_optional(logo_background)
      end

      def slug
        name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
      end

      def local?
        badge == "local"
      end

      # Active when today is within the inclusive since/until window.
      def active?(today = Date.today)
        (since.nil? || since <= today) && (until_date.nil? || until_date >= today)
      end

      # Stable representation used for checksumming.
      def to_h
        {
          "name" => name,
          "href" => href,
          "since" => since&.iso8601,
          "until" => until_date&.iso8601,
          "description" => description,
          "badge" => badge,
          "kind" => kind,
          "logo" => logo,
          "label" => label,
          "color" => color,
          "logo_background" => logo_background
        }
      end

      # Registry form: the keys Config reads back, nils, blanks, and defaults omitted.
      def to_registry_h
        {
          "name" => name,
          "target_href" => href,
          "since" => since&.iso8601,
          "until" => until_date&.iso8601,
          "description" => description,
          "badge" => (badge unless badge == "central"),
          "kind" => (kind unless kind == "financial"),
          "logo" => logo,
          "label" => label,
          "color" => color,
          "logo_background" => logo_background
        }.reject { |_, v| v.nil? || v == "" }
      end

      private

      def parse_date(value)
        return if value.nil? || value.to_s.strip.empty?
        return value if value.is_a?(Date)

        Date.parse(value.to_s)
      rescue Date::Error
        raise Error, "sponsor #{name.inspect} has an invalid date: #{value.inspect}"
      end

      def normalize_logo(value)
        str = value.to_s.strip
        return if str.empty?
        return str if str.start_with?("data:image/") || str.match?(%r{\Ahttps?://}i)
        raise Error, "sponsor #{@name.inspect} has an unsafe logo scheme: #{str.inspect}" if str.match?(/\A[a-z][a-z0-9+.-]*:/i) && !str.match?(/\A[A-Za-z]:[\/\\]/)

        str
      end

      def normalize_optional(value)
        str = value.to_s.strip
        str.empty? ? nil : str
      end
    end
  end
end
