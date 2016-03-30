require 'json'
require 'slnky/ext/deep_struct'

module Slnky
  class Data < DeepStruct
    def initialize(hash={})
      if hash.is_a?(Slnky::Data)
        hash = hash.to_h
      end
      super(hash)
    end

    def to_s
      to_h.to_json
    end

    def delete(name)
      self.delete_field(name) || self.delete_field(name.to_s)
    end

    class << self
      def parse(str)
        new(JSON.parse(str))
      end
    end
  end
end
