require 'json'
require 'slnky/ext/deep_struct'

module Slnky
  class Message < DeepStruct
    class << self
      def parse(str)
        new(JSON.parse(str))
      end
    end

    def to_s
      to_h.to_json
    end
  end
end
