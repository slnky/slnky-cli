require 'slnky'
require 'yaml'
require 'thor'
require 'active_support/all'

path = File.expand_path("../cli", __FILE__)
Dir["#{path}/**/*.rb"].each do |file|
  require file
end

module Slnky
  module CLI
    class Main < Thor
      map %w[--version -v] => :__print_version

      desc "--version, -v", "print the version"
      def __print_version
        puts "Slnky version: #{Slnky::VERSION}"
      end

      desc 'init', 'initialize configuration directory'
      def init
        dir = "#{ENV['HOME']}/.slnky"
        FileUtils.mkdir_p(dir)
        defaults = {
            slnky: {
                url: 'http://localhost:3000'
            }
        }.deep_stringify_keys
        File.open("#{dir}/config.yaml", "w+") {|f| f.write(defaults.to_yaml)}
      end

      desc 'generate', 'generate slnky objects from templates'
      subcommand 'generate', Slnky::CLI::Generate
    end
  end
end
