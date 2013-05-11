require 'capistrano_colors' if $stdout.tty? and $stderr.tty?

set :application, "set your application name here"
set :repository,  "set your repository location here"

role :chef, "localhost"  # Put your servers here (you can put multiple servers: ex. "server1", "server2", "server3"...)

# authentication info (example)
set :user, 'vagrant'
set :password, 'vagrant'
ssh_options[:port] = "2222"
ssh_options[:keys] = ["#{ENV['HOME']}/.ssh/your_key_for_auth.pem"]

# for deploy:setup
set(:home_directory) { capture("echo $HOME").strip }
set(:deploy_to) { File.join(fetch(:home_directory), 'deploy') }

# for paratrooper:chef
require 'capistrano-paratrooper-chef'
require 'capistrano-paratrooper-chef/omnibus_install'
set :chef_roles_auto_discovery, true
