# frozen_string_literal: true

require "fileutils"

module Kettle
  module Sponsors
    # Writes desktop, phone, and small Shields-style SVGs for a set of sponsors
    # into a directory, skipping all work when the active-sponsor checksum is
    # unchanged.
    module Renderer
      module_function

      # @param sponsors [Array<Sponsor>]
      # @param out [String] output directory
      # @param today [Date]
      # @param force [Boolean]
      # @param theme [Theme]
      # @param base_dir [String, nil] base directory for resolving relative local logo paths
      # @param include_shields [Boolean] whether to also write +shield/<slug>.svg+ (default true)
      # @param _options [Hash] forward-compatible options
      # @return [Array<String>] paths written (empty when up to date)
      def render(sponsors, out:, today: Date.today, force: false, theme: Theme.new, base_dir: nil, include_shields: true, **_options)
        active = sponsors.select { |s| s.active?(today) }
        sum = Checksum.compute(sponsors, today: today, theme: theme)
        return [] if !force && Checksum.current?(out, sum)

        FileUtils.mkdir_p(File.join(out, "phone"))
        FileUtils.mkdir_p(File.join(out, "shield")) if include_shields
        written = []
        # Stale files (expired or removed sponsors) are removed so output matches config.
        Dir[File.join(out, "{,phone/,shield/}*.svg")].each { |f| File.delete(f) }
        variants = {"" => :desktop, "phone" => :phone}
        variants["shield"] = :shield if include_shields

        active.each do |s|
          logo_uri = LogoLoader.resolve(
            s.logo,
            base_dir: base_dir,
            fetch: theme.fetch_logos?,
            cache_dir: theme.logo_cache,
            refresh: force
          )
          variants.each do |sub, variant|
            path = File.join(out, sub, "#{s.slug}.svg")
            File.write(path, BadgeRenderer.svg(s, variant: variant, theme: theme, logo_uri: logo_uri, base_dir: base_dir))
            written << path
          end
        end
        Checksum.write(out, sum)
        written
      end

      # @param sponsors [Array<Sponsor>]
      # @param out [String]
      # @param today [Date]
      # @param theme [Theme]
      # @param _options [Hash] forward-compatible options
      # @return [Boolean]
      def stale?(sponsors, out:, today: Date.today, theme: Theme.new, **_options)
        !Checksum.current?(out, Checksum.compute(sponsors, today: today, theme: theme))
      end
    end
  end
end
