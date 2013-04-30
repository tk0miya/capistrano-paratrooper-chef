require 'capistrano-paratrooper-chef'

Capistrano::Configuration.instance.load do
  namespace :paratrooper do
    namespace :chef do
      desc "Installs chef (by omnibus installer)"
      task :install_omnibus_chef do
        run "curl -L http://www.opscode.com/chef/install.sh | #{top.sudo} bash"
      end
      after "deploy:setup" "paratrooper:chef:install_omnibus_chef"
    end
  end
end
