require 'redis'
require 'json'

module Slnky
  class << self
    def brain
      Slnky::Brain::Base.instance
    end
  end
  module Brain
    class Base
      class << self
        def instance
          @brain ||= self.new(Slnky.config.redis.to_h)
        end

        def connect(config)
          @brain = self.new(config)
        end
      end

      def initialize(redis={})
        @options = {
            host: '127.0.0.1',
            port: 6379,
            user: nil,
            pass: nil,
            db: '15'
        }
        @options.merge!(redis) if redis
        userpass = @options[:user] ? "#{@options[:user]}:#{@options[:pass]}" : ''
        @redis = Redis.new(url: "redis://#{userpass}#{@options[:host]}:#{@options[:port]}/#{@options[:db]}")
      end

      # def keys(pattern='*')
      #   @redis.keys(pattern)
      # end
      #
      # def set(key, value)
      #   @redis.set key, value.is_a?(String) ? value : value.to_json
      # end
      #
      # def get(key)
      #   val = @redis.get key
      #   begin
      #     JSON.parse(val)
      #   rescue
      #     val
      #   end
      # end

      def hset(key, field, value)
        @redis.hset("slnky.#{key}", field, value.is_a?(String) ? value : value.to_json)
      end

      def hget(key, field)
        val = @redis.hget("slnky.#{key}", field)
        begin
          JSON.parse(val)
        rescue
          val
        end
      end

      def hgetall(key)
        keys = @redis.hkeys("slnky.#{key}")
        keys.inject({}) {|h, e| h[e] = hget(key, e); h}
      end
    end
  end
end