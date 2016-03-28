require 'capistrano/slnky/helpers'

include Capistrano::Slnky::Helpers

namespace :load do
  task :defaults do
    set :slnky_service, -> { "#{fetch(:application)}-#{fetch(:stage)}" }
    set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids')
    set :linked_files, fetch(:linked_files, []).push('.env')
    set :templates_path, 'config/templates'
  end
end

namespace :slnky do
  task :mkdir do
    execute :mkdir, '-pv', shared_path
  end

  desc 'upload upstart config'
  task :upstart do
    on roles :app do
      sudo_upload! template('upstart.conf.erb'), "/etc/init/#{fetch(:slnky_service)}.conf"
    end
  end

  [:start, :stop, :restart].each do |command|
    desc "#{command} slnky service"
    task command do
      on roles :app do
        sudo 'service', fetch(:slnky_service), command
      end
    end
  end
end

namespace :deploy do
  after :publishing, 'slnky:restart'

  desc "push deploy.env to service's shared_path on the server"
  task :dotenv do
    on roles :app do
      upload! 'deploy.env', "#{shared_path}/.env"
    end
  end
end

desc 'setup task'
task :setup do
  invoke 'slnky:mkdir'
  invoke 'slnky:upstart'
  invoke 'deploy:dotenv'
end
