require 'slnky/command/request'
require 'slnky/command/response'

require 'slop'

module Slnky
  module Command
    class Base
      def initialize(config={})
        @config = load_config(config)
      end

      def load_config(config)
        Slnky::Data.new(config)
      end

      def options(args, &block)
        Slop.parse(args) do |slop|
          yield slop
        end
      end
    end
  end
end
