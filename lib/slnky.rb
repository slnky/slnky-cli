require 'slnky/version'
require 'slnky/data'
require 'slnky/message'
require 'slnky/service'
require 'slnky/generator'

require 'rest_client'

module Slnky
  class << self
    def version
      Slnky::VERSION
    end

    def config
      load_config unless @config
      @config
    end

    def load_config(file='~/.slnky/config.yaml')
      path = File.expand_path(file)
      @config = Slnky::Data.new(YAML.load_file(path))
    end

    def notify(msg, server=nil)
      server ||= config.slnky.url
      params = {name: msg.name, event: msg.to_h}
      RestClient.post "#{server}/hooks/notify", params.to_json, content_type: :json, accept: :json
    end
  end
end
