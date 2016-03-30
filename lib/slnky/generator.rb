require 'erb'
require 'tilt'
require 'find'

module Slnky
  module Generator
    class Base
      require 'highline/import'
      attr_reader :name
      attr_reader :dir

      def initialize(name, options={})
        options = {
            force: false,
        }.merge(options)
        @name = name
        @service = "slnky-#{name}"
        @dir = File.expand_path("./#{@service}")
        short = self.class.name.split('::').last.downcase
        @template = File.expand_path("../template/#{short}", __FILE__)
        @force = options[:force]
      end

      def generate
        say "<%= color('generating service #{@name}', BOLD) %>"
        # puts "  from: #{@template}"
        # puts "  to:   #{@dir}"
        process_files
        # make service executable
        `chmod 755 #{@dir}/service-slnky-#{@name}`
        # git init
        if File.directory?("#{@dir}/.git")
          puts "git already initialized"
        else
          puts "initializing git..."
          `cd #{@dir} && git init . || true`
          `cd #{@dir} && git add .`
        end
      end

      protected

      def askyn(message, options={})
        options = {
            choices: 'yn',
        }.merge(options)
        answer = ask("<%= color('#{message}', BOLD) %> [#{options[:choices]}]") do |q|
          q.echo = false
          q.character = true
          q.validate = /\A[#{options[:choices]}]\Z/
        end
        answer == 'y'
      end

      def process_files
        Find.find(@template).each do |path|
          next unless File.file?(path)
          file = path.gsub(/^#{@template}\//, '').gsub('NAME', @name)
          ext = File.extname(path)
          mkdir(File.dirname("#{@dir}/#{file}"))
          dest = "#{@dir}/#{file}".gsub(/\.erb$/, '')
          say "  <%= color('#{dest.gsub(/^#{File.expand_path('.')}\//, '')}', GREEN) %>"
          if ext == '.erb'
            dest = dest
            tmpl(path, dest) if !File.exists?(dest) || @force || askyn('    overwrite file?')
          else
            file(path, dest) if !File.exists?(dest) || @force || askyn('    overwrite file?')
          end
        end
      end

      def mkdir(dir)
        return if File.directory?(dir)
        # puts "mkdir: #{dir}"
        FileUtils.mkdir_p(dir)
      end

      def file(path, dest)
        # puts "file:  #{file}"
        FileUtils.cp(path, dest)
      end

      def tmpl(path, dest)
        # puts "tmpl:  #{file}"
        var = {
            name: @name,
            dir: @dir,
            cap: @name.capitalize,
            service: @service
        }
        # out = file.gsub(/\.erb$/, '')
        # dest = "#{@dir}/#{out}"
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
