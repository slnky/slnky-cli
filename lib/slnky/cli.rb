require 'yaml'
require 'clamp'
require 'active_support/all'
require 'highline'

require 'slnky'
require 'slnky/generator'

module Slnky
  module CLI
    class Base < Clamp::Command
      option %w{-v --version}, :flag, 'print version' do |v|
        puts "Slnky version: #{Slnky::VERSION}"
        exit(0)
      end

      option %w{-c --config}, '[CONFIG]', 'set config directory location', default: '~/.slnky/config.yaml', environment_variable: 'SLNKY_CONFIG' do |c|
        ENV['SLNKY_CONFIG'] = c
      end
      option %w{-s --server}, '[URL]', 'set server url', environment_variable: 'SLNKY_URL' do |u|
        ENV['SLNKY_URL'] = u
      end
      option %w{-e --environment}, '[ENV]', 'the environment to run under', default: 'development', environment_variable: 'SLNKY_ENV' do |e|
        ENV['SLNKY_ENV'] = e
      end
    end

    class Main < Base
      subcommand 'init', 'initialize the configuration directory' do
        parameter '[SERVER]', 'the server to point to', default: 'http://localhost:3000'

        def execute
          dir = "#{ENV['HOME']}/.slnky"
          FileUtils.mkdir_p(dir)
          defaults = {
              slnky: {
                  development: {
                    url: server
                  }
              }
          }.deep_stringify_keys
          File.open("#{dir}/config.yaml", "w+") { |f| f.write(defaults.to_yaml) }
        end
      end
    end
  end
end

path = File.expand_path("../cli", __FILE__)
Dir["#{path}/**/*.rb"].each do |file|
  require file
end
