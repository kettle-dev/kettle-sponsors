# frozen_string_literal: true

require "date"

module Kettle
  module Sponsors
    # One sponsor entry, normalized from a +corporate_sponsors+ hash.
    class Sponsor
      BADGE_MODES = %w[central local].freeze

      attr_reader :name, :href, :since, :until_date, :description, :badge

      def self.from_h(hash)
        new(
          name: hash["name"],
          href: hash["target_href"] || hash["url"],
          since: hash["since"],
          until_date: hash["until"],
          description: hash["description"],
          badge: hash["badge"]
        )
      end

      def initialize(name:, href:, since: nil, until_date: nil, description: nil, badge: nil)
        @name = name.to_s.strip
        raise Error, "sponsor requires a name" if @name.empty?

        @href = href.to_s.strip
        raise Error, "sponsor #{@name.inspect} has a non-http(s) link: #{@href.inspect}" unless @href.empty? || @href.match?(%r{\Ahttps?://}i)

        @since = parse_date(since)
        @until_date = parse_date(until_date)
        @description = description.to_s.strip
        @badge = (badge || "central").to_s
        raise Error, "sponsor #{@name.inspect} has unknown badge mode #{@badge.inspect}" unless BADGE_MODES.include?(@badge)
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
          "name" => name, "href" => href, "since" => since&.iso8601,
          "until" => until_date&.iso8601, "description" => description, "badge" => badge
        }
      end

      private

      def parse_date(value)
        return if value.nil? || value.to_s.strip.empty?
        return value if value.is_a?(Date)

        Date.parse(value.to_s)
      rescue Date::Error
        raise Error, "sponsor #{name.inspect} has an invalid date: #{value.inspect}"
      end
    end
  end
end
