# frozen_string_literal: true

require "fileutils"

module Kettle
  module Sponsors
    # Writes desktop and phone SVGs for a set of sponsors into a directory,
    # skipping all work when the active-sponsor checksum is unchanged.
    module Renderer
      module_function

      # @return [Array<String>] paths written (empty when up to date)
      def render(sponsors, out:, today: Date.today, force: false)
        active = sponsors.select { |s| s.active?(today) }
        sum = Checksum.compute(sponsors, today: today)
        return [] if !force && Checksum.current?(out, sum)

        FileUtils.mkdir_p(File.join(out, "phone"))
        written = []
        # Stale files (expired or removed sponsors) are removed so output matches config.
        Dir[File.join(out, "{,phone/}*.svg")].each { |f| File.delete(f) }
        active.each do |s|
          {"" => :desktop, "phone" => :phone}.each do |sub, variant|
            path = File.join(out, sub, "#{s.slug}.svg")
            File.write(path, BadgeRenderer.svg(s, variant: variant))
            written << path
          end
        end
        Checksum.write(out, sum)
        written
      end

      def stale?(sponsors, out:, today: Date.today)
        !Checksum.current?(out, Checksum.compute(sponsors, today: today))
      end
    end
  end
end
