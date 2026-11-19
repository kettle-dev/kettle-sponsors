# frozen_string_literal: true

require "digest"
require "json"

module Kettle
  module Sponsors
    # Checksum of only the active sponsors, so unrelated config edits and
    # expired sponsors are accounted for exactly once.
    module Checksum
      FILENAME = ".checksum"

      module_function

      def compute(sponsors, today: Date.today)
        payload = sponsors.select { |s| s.active?(today) }.map(&:to_h)
        Digest::SHA256.hexdigest(JSON.generate(payload))
      end

      def current?(dir, sum)
        path = File.join(dir, FILENAME)
        File.file?(path) && File.read(path).strip == sum
      end

      def write(dir, sum)
        File.write(File.join(dir, FILENAME), "#{sum}\n")
      end
    end
  end
end
