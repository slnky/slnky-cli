require 'open-uri'
require 'json'
require 'yaml'
require 'erb'
require 'tilt'
require 'dotenv'
Dotenv.load

module Slnky
  class << self
    def config
      Slnky::Config.instance
    end
  end

  class Config < Data
    class << self
      def configure(name, config={})
        @name = name
        @config ||= begin
          config['service'] = name
          config['environment'] ||= 'development'
          file = ENV['SLNKY_CONFIG']||"~/.slnky/config.yaml"
          config.merge!(config_file(file))
          server = ENV['SLNKY_SERVER'] || config['url']
          config.merge!(config_server(server))
          self.new(config)
        end
      end

      # def load_file(file)
      #   self.load(YAML.load_file(File.expand_path(file)))
      # end

      def instance
        @config || configure('unknown')
      end

      def reset!
        @config = nil
      end

      # def merge(config)
      #   @config.merge!(config)
      # end

      protected

      def config_file(file)
        path = File.expand_path(file)
        return {} unless File.exists?(path)
        template = Tilt::ERBTemplate.new(path)
        output = template.render(self, {})
        d = YAML.load(output)
        d['slnky'] ? d['slnky'] : d
      rescue => e
        puts "failed to load file #{file}: #{e.message}"
        {}
      end

      def config_server(server)
        return {} unless server
        server = "https://#{server}" unless server =~ /^http/
        JSON.parse(open("#{server}/configs/#{@name}") { |f| f.read })
      rescue => e
        puts "failed to load server #{server}: #{e.message}"
        {}
      end
    end

    def development?
      !self.environment || self.environment == 'development'
    end

    def production?
      self.environment == 'production'
    end

    def test?
      self.environment == 'test'
    end
  end
end
