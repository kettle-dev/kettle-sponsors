# frozen_string_literal: true

require "version_gem"
require_relative "sponsors/version"

module Kettle
  # Sponsor badges for kettle-jem managed projects.
  #
  # Sponsors are read from +readme.corporate_sponsors+ in
  # +.structuredmerge/kettle-jem.yml+. By default each badge is served from the
  # central logos site; sponsors marked +badge: local+ are rendered into the
  # project instead.
  module Sponsors
    class Error < StandardError; end

    # Base URL of the central badge host (https://logos.galtzo.com).
    CENTRAL_BASE = "https://logos.galtzo.com/assets/images/sponsors"
    # Default directory (relative to the project root) for locally rendered badges.
    LOCAL_DIR = "docs/assets/images/sponsors"
    CONFIG_PATH = ".structuredmerge/kettle-jem.yml"

    autoload :Sponsor, "kettle/sponsors/sponsor"
    autoload :Config, "kettle/sponsors/config"
    autoload :Checksum, "kettle/sponsors/checksum"
    autoload :BadgeRenderer, "kettle/sponsors/badge_renderer"
    autoload :Markup, "kettle/sponsors/markup"
    autoload :Renderer, "kettle/sponsors/renderer"
    autoload :Verifier, "kettle/sponsors/verifier"
    autoload :CLI, "kettle/sponsors/cli"
    autoload :Plugin, "kettle/sponsors/plugin"

    class << self
      # Entry point called by kettle-jem when this gem is listed under +plugins:+.
      def register_kettle_jem_plugin(registrar)
        Plugin.register!(registrar)
      end
    end
  end
end

Kettle::Sponsors::Version.class_eval do
  extend VersionGem::Basic
end
