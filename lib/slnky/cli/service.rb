module Slnky
  module CLI
    class Service < Base
      subcommand 'run', 'run service named NAME' do
        parameter 'NAME', 'the name of the service'
        # option %w{-f --force}, :flag, "force overwrite of files"
        option %w{-e --environment}, '[ENV]', 'the environment to run under', default: 'development', environment_variable: 'SLNKY_ENV'
        def execute
          lib = File.expand_path("#{Dir.pwd}/lib", __FILE__)
          $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

          require 'rubygems'
          require 'bundler/setup'
          require 'dotenv'
          Dotenv.load

          require 'slnky'
          require "slnky/#{name}"

          Slnky::Config.reset!
          Slnky::Config.configure(name, 'environment' => environment)
          Slnky::Chef::Service.new.start
        rescue => e
          puts "failed to run service #{name}: #{e.message} at #{e.backtrace.first}"
        end
      end
    end
  end
end
Slnky::CLI::Main.subcommand 'service', 'manage service', Slnky::CLI::Service