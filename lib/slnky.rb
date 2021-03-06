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
require 'slnky/brain'
require 'slnky/transport'
require 'slnky/service'
require 'slnky/client'
require 'slnky/command'

module Slnky
  class << self
    def version
      Slnky::VERSION
    end

    def heartbeat(name)
      # server = ENV['SLNKY_URL'] || Slnky.config.url
      # RestClient.post "#{server}/hooks/heartbeat", {name: name}, content_type: :json, accept: :json
      Slnky.brain.hset(:heartbeat, name, Time.now.to_i)
    end

    def notify(msg)
      server = self.config.url
      params = {name: msg.name, event: msg.to_h}
      RestClient.post "#{server}/hooks/notify", params.to_json, content_type: :json, accept: :json
    end
  end
end
