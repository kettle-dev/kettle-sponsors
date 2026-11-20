# frozen_string_literal: true

require "yaml"
require "fileutils"

module Kettle
  module Sponsors
    # A registry is a YAML file with a top-level +sponsors:+ list, one entry per
    # slug. It is the input of the central badge host (logos.galtzo.com).
    module Registry
      HEADER = "# Sponsor registry. Merged by `kettle-sponsors publish`; badges are rendered from it.\n"

      module_function

      # Merge +incoming+ into +existing+ by slug. Incoming wins; registry-only
      # entries are kept. Output is sorted by slug so it is deterministic.
      def merge(existing, incoming)
        by_slug = existing.to_h { |s| [s.slug, s] }
        incoming.each { |s| by_slug[s.slug] = s }
        by_slug.sort.map(&:last)
      end

      def dump(sponsors)
        HEADER + {"sponsors" => sponsors.map(&:to_registry_h)}.to_yaml.sub(/\A---\s*\n/, "")
      end

      # @return [Boolean] true when the registry file changed
      def publish(from:, registry:)
        incoming = Config.load(from)
        raise Error, "no sponsors found in #{from}" if incoming.empty?

        output = dump(merge(Config.load(registry), incoming))
        return false if File.file?(registry) && File.read(registry) == output

        FileUtils.mkdir_p(File.dirname(registry))
        File.write(registry, output)
        true
      end
    end
  end
end
