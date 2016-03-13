module Slnky
  module CLI
    class Generate < Thor
      desc 'service NAME [DIR]', 'generate a service named NAME'
      def service(name, dir=nil)
        generator = Slnky::Generator::Service.new(name, dir)
        generator.generate
      end

      desc 'command NAME [DIR]', 'generate a service named NAME'
      def command(name, dir=nil)
        raise Thor::Error, "not implemented"
        # Slnky::Generator::Command.new(name, dir).generate
      end
    end
  end
end
