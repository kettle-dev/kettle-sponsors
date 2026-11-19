# frozen_string_literal: true

require "yaml"
require "date"

module Kettle
  module Sponsors
    # Loads sponsors from a kettle-jem config file or a standalone registry.
    module Config
      module_function

      # @param path [String] kettle-jem.yml (sponsors under readme.corporate_sponsors)
      #   or a registry file with a top-level +sponsors:+ list.
      # @return [Array<Sponsor>] all sponsors, active or not, in file order
      def load(path)
        return [] unless File.file?(path)

        data = YAML.safe_load_file(path, permitted_classes: [Date], aliases: true) || {}
        entries = data["sponsors"] || data.dig("readme", "corporate_sponsors")
        sponsors = Array(entries).map { |entry| Sponsor.from_h(entry) }
        dupes = sponsors.group_by(&:slug).select { |_, list| list.size > 1 }.keys
        raise Error, "sponsor slug collision: #{dupes.join(", ")}" unless dupes.empty?

        sponsors
      end
    end
  end
end
