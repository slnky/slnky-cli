module Slnky
  module Client
    class Base
      def initialize

      end

      protected

      def config
        Slnky.config
      end

      def log
        Slnky.log
      end
    end

    class Mock < Base

    end
  end
end
