require 'rest_client'
require 'active_support/all'
require 'open-uri'
require 'json'

require 'slnky/version'
require 'slnky/data'
require 'slnky/config'
require 'slnky/log'
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

    def log
      Slnky::Log.instance
    end

    def heartbeat(server, name)
      RestClient.post "#{server}/hooks/heartbeat", {name: name}, content_type: :json, accept: :json
    end

    def notify(msg)
      server = self.config.url
      params = {name: msg.name, event: msg.to_h}
      RestClient.post "#{server}/hooks/notify", params.to_json, content_type: :json, accept: :json
    end
  end
end
