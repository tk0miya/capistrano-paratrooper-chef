require 'capistrano_colors' if $stdout.tty? and $stderr.tty?
require 'capistrano/ext/multistage'

set :application, "set your application name here"
set :repository,  "set your repository location here"

# for deploy:setup
set(:home_directory) { capture("echo $HOME").strip }
set(:deploy_to) { File.join(fetch(:home_directory), 'deploy') }

# for paratrooper:chef
require 'capistrano-paratrooper-chef'
require 'capistrano-paratrooper-chef/omnibus_install'
set :chef_roles_auto_discovery, true
