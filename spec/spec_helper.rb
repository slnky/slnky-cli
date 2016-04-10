$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'json'
require 'yaml'
require 'erb'
require 'tilt'

require 'dotenv'
@dotenv = Dotenv.load

require 'slnky'

RSpec.configure do |config|
  config.before(:all) do
    Slnky::Config.reset!
    Slnky::Config.configure('spec', test_config)
  end
end

def event(name)
  @events ||= {}
  @events[name] ||= begin
    file = File.expand_path("../../test/events/#{name}.json", __FILE__)
    raise "file #{file} not found" unless File.exists?(file)
    Slnky::Message.new(JSON.parse(File.read(file)))
  end
end

def command(name)
  @commands ||= {}
  @commands[name] ||= begin
    file = File.expand_path("../../test/commands/#{name}.json", __FILE__)
    raise "file #{file} not found" unless File.exists?(file)
    Slnky::Command::Request.new(JSON.parse(File.read(file)))
  end
end

def test_config
  @config ||= begin
    file = File.expand_path("../../test/config.yaml", __FILE__)
    template = Tilt::ERBTemplate.new(file)
    output = template.render(self, @dotenv)
    YAML.load(output)
  end
end
