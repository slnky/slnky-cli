module Slnky
  module CLI
    class Generate < Base
      subcommand 'service', 'generate a service named NAME' do
        parameter 'NAME', 'the name of the service'
        def execute
          generator = Slnky::Generator::Service.new(name, dir)
          generator.generate
        end
      end

      subcommand 'command', 'generate a command named NAME' do
        parameter 'NAME', 'the name of the command'
        def execute
          raise 'not implemented'
        end
      end
    end
  end
end
Slnky::CLI::Main.subcommand 'generate', 'generate from templates', Slnky::CLI::Generate
