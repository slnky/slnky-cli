module Slnky
  module CLI
    class Service < Base
      subcommand 'run', 'run service named NAME' do
        parameter 'NAME', 'the name of the service' do |n|
          n.gsub(/^slnky-/, '')
        end
        # option %w{-f --force}, :flag, "force overwrite of files"
        option %w{-t --trace}, :flag, "print full backtrace on error"
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

          klass = "Slnky::#{name.capitalize}::Service".constantize
          klass.new.start
        rescue => e
          puts "failed to run service #{name}: #{e.message} at #{e.backtrace.first}"
          if trace?
            e.backtrace.each do |b|
              puts "  #{b}"
            end
          end
        end
      end
    end
  end
end
Slnky::CLI::Main.subcommand 'service', 'manage service', Slnky::CLI::Service
