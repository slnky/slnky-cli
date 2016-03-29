require 'slnky/command/request'
require 'slnky/command/response'

module Slnky
  module Command
    class Base
      def initialize(config={})
        @config = load_config(config)
      end

      def load_config(config)
        Slnky::Data.new(config)
      end
    end
  end
end
