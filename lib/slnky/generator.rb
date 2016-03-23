require 'erb'
require 'tilt'
require 'find'

module Slnky
  module Generator
    class Base
      attr_reader :name
      attr_reader :dir

      def initialize(name)
        @name = name
        @dir = File.expand_path("slnky-#{name}")
        short = self.class.name.split('::').last.downcase
        @template = File.expand_path("../template/#{short}", __FILE__)
      end

      def generate
        puts "generating service #{@name}:"
        puts "  from: #{@template}"
        puts "  to:   #{@dir}"
        process_files
        # make service executable
        `chmod 755 #{@dir}/service-slnky-#{@name}`
        # git init
        puts "initializing git..."
        `cd #{@dir} && git init . || true`
        `cd #{@dir} && git add .`
      end

      protected

      def process_files
        Find.find(@template).each do |path|
          next unless File.file?(path)
          file = path.gsub(/^#{@template}\//, '')
          ext = File.extname(path)
          mkdir(File.dirname("#{@dir}/#{file}"))
          if ext == '.erb'
            tmpl(file)
          else
            file(file)
          end
        end
      end

      def mkdir(dir)
        return if File.directory?(dir)
        # puts "mkdir: #{dir}"
        FileUtils.mkdir_p(dir)
      end

      def file(file)
        # puts "file:  #{file}"
        FileUtils.cp("#{@template}/#{file}", "#{@dir}/#{file}")
      end

      def tmpl(file)
        # puts "tmpl:  #{file}"
        path = "#{@template}/#{file}"
        var = {
            name: @name,
            dir: @dir
        }
        out = file.gsub(/\.erb$/, '').gsub('NAME', @name)
        dest = "#{@dir}/#{out}"
        # puts "       #{dest}"
        template = Tilt.new(path)
        output = template.render(self, var)
        File.write(dest, output)
      end

      # def generate_old
      #   # copy dir
      #   puts "creating directory and processing templates..."
      #   FileUtils.cp_r(@template, @dir)
      #   puts "#{@dir}:"
      #   # process templates
      #   Find.find(@dir).each do |f|
      #     next unless File.file?(f) && File.extname(f) == '.erb'
      #     template(f)
      #   end
      #   # make service executable
      #   `chmod 755 #{@dir}/service-slnky-#{@name}`
      #   # git init
      #   puts "initializing git..."
      #   `cd #{@dir} && git init . || true`
      # end
    end
  end
end

require 'slnky/generator/command'
require 'slnky/generator/service'
