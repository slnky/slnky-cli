require 'rest_client'
require 'active_support/all'
require 'open-uri'
require 'json'

require 'slnky/version'
require 'slnky/data'
require 'slnky/system'
require 'slnky/message'
require 'slnky/service'
require 'slnky/transport'
require 'slnky/command'

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

    def get_server_config(server, name)
      JSON.parse(open("#{server}/configs/#{name}") {|f| f.read })
    end

    def heartbeat(server, name)
      RestClient.post "#{server}/hooks/heartbeat", {name: name}, content_type: :json, accept: :json
    end

    def notify(msg, server=nil)
      server ||= config.slnky.url
      params = {name: msg.name, event: msg.to_h}
      RestClient.post "#{server}/hooks/notify", params.to_json, content_type: :json, accept: :json
    end
  end
end
