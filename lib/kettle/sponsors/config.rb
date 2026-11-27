# frozen_string_literal: true

require "yaml"
require "date"

module Kettle
  module Sponsors
    # Loads sponsors and optional theme settings from a kettle-jem config file
    # or a standalone registry.
    module Config
      module_function

      # @param path [String] kettle-jem.yml (sponsors under readme.corporate_sponsors)
      #   or a registry file with a top-level +sponsors:+ list.
      # @return [Array<Sponsor>] all sponsors, active or not, in file order
      def load(path)
        data = read_yaml(path)
        return [] if data.empty?

        entries = data["sponsors"] || data.dig("readme", "corporate_sponsors") ||
          data.dig("sponsorships", "corporate") || data["corporate_sponsors"]
        sponsors = Array(entries).map { |entry| Sponsor.from_h(entry) }
        dupes = sponsors.group_by(&:slug).select { |_, list| list.size > 1 }.keys
        raise Error, "sponsor slug collision: #{dupes.join(", ")}" unless dupes.empty?

        sponsors
      end

      # Load theme settings from +readme.sponsor_theme+, +sponsor_theme+, or +theme+.
      #
      # @param path [String] path to config or registry YAML
      # @return [Theme]
      def load_theme(path)
        data = read_yaml(path)
        raw = data.dig("readme", "sponsor_theme") || data["sponsor_theme"] || data["theme"]
        Theme.from_h(raw)
      end

      # Load both sponsors and theme from +path+.
      #
      # @param path [String]
      # @return [Hash{Symbol => Object}] +{sponsors: Array<Sponsor>, theme: Theme}+
      def load_all(path)
        {sponsors: load(path), theme: load_theme(path)}
      end

      def read_yaml(path)
        return {} unless File.file?(path)

        YAML.safe_load_file(path, permitted_classes: [Date], aliases: true) || {}
      end
    end
  end
end
