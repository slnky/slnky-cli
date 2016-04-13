require 'json'
require 'yaml'
require 'erb'
require 'tilt'
require 'dotenv'
require 'slnky'

def slnky_event(name)
  @events ||= {}
  @events[name] ||= begin
    file = File.expand_path("#{Dir.pwd}/test/events/#{name}.json", __FILE__)
    raise "file #{file} not found" unless File.exists?(file)
    Slnky::Message.new(JSON.parse(File.read(file)))
  end
end

def slnky_command(name)
  @commands ||= {}
  @commands[name] ||= begin
    file = File.expand_path("#{Dir.pwd}/test/commands/#{name}.json", __FILE__)
    raise "file #{file} not found" unless File.exists?(file)
    Slnky::Command::Request.new(JSON.parse(File.read(file)))
  end
end

def slnky_response(route, service)
  @responses ||= {}
  @responses[route] ||= begin
    response = Slnky::Command::Response.new(route, service)
    response.exchange = Slnky::Transport::MockExchange.new
    response
  end
end

ENV['SLNKY_CONFIG'] = File.expand_path("#{Dir.pwd}/test/config.yaml", __FILE__)
Slnky::Config.configure('spec')
