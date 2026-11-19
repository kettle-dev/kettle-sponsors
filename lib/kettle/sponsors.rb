# frozen_string_literal: true

require "version_gem"
require_relative "sponsors/version"

module Kettle
  module Sponsors
    class Error < StandardError; end
    # Your code goes here...
  end
end

Kettle::Sponsors::Version.class_eval do
  extend VersionGem::Basic
end
