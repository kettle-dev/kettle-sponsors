# frozen_string_literal: true

require "cgi"

module Kettle
  module Sponsors
    # Inline 12x12 monochrome vector icons and labels for sponsorship kinds.
    # Pure SVG paths avoid OS-dependent emoji rendering differences.
    module Icons
      LABELS = {
        "financial" => "Financial",
        "compute" => "Compute",
        "time" => "Engineer time",
        "services" => "Services"
      }.freeze

      SHIELD_LABELS = {
        "financial" => "sponsor",
        "compute" => "compute",
        "time" => "eng time",
        "services" => "services"
      }.freeze

      module_function

      # @param kind [String] one of Sponsor::KINDS
      # @return [String] display label for desktop badges
      def label(kind)
        LABELS.fetch(kind.to_s, "Sponsor")
      end

      # @param kind [String] one of Sponsor::KINDS
      # @return [String] compact label for Shields.io-style small badges
      def shield_label(kind)
        SHIELD_LABELS.fetch(kind.to_s, "sponsor")
      end

      # @param kind [String] one of Sponsor::KINDS
      # @param color [String] stroke color for the icon
      # @param _options [Hash] forward-compatible options
      # @return [String] SVG elements sized for a 12x12 coordinate box
      def svg(kind, color:, **_options)
        c = CGI.escapeHTML(color.to_s)
        case kind.to_s
        when "compute"
          %(<rect x="3" y="3" width="6" height="6" rx="1" fill="none" stroke="#{c}" stroke-width="1.15"/>) +
            %(<path d="M4.5 1v2M7.5 1v2M4.5 9v2M7.5 9v2M1 4.5h2M1 7.5h2M9 4.5h2M9 7.5h2" stroke="#{c}" stroke-width="1.15" stroke-linecap="round"/>)
        when "time"
          %(<circle cx="6" cy="6" r="4.8" fill="none" stroke="#{c}" stroke-width="1.15"/>) +
            %(<path d="M6 3.2V6l2 1.3" fill="none" stroke="#{c}" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>)
        when "services"
          %(<path d="M9.8 2.2a2.5 2.5 0 0 0-3.3 3.3L2.3 9.7a1 1 0 1 0 1.4 1.4l4.2-4.2a2.5 2.5 0 0 0 3.3-3.3L9.6 5.2 8.2 3.8l1.6-1.6Z" fill="none" stroke="#{c}" stroke-width="1.1" stroke-linejoin="round"/>)
        else
          %(<circle cx="6" cy="6" r="5" fill="none" stroke="#{c}" stroke-width="1.15"/>) +
            %(<path d="M6 2.8v6.4M7.7 4.4c0-.7-.7-1.1-1.7-1.1s-1.6.4-1.6 1c0 .7.6 1 1.7 1.2 1.1.2 1.7.6 1.7 1.3 0 .7-.8 1.2-1.8 1.2s-1.7-.4-1.8-1.1" fill="none" stroke="#{c}" stroke-width="1.15" stroke-linecap="round"/>)
        end
      end
    end
  end
end
