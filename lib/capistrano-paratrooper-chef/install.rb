require 'capistrano-paratrooper-chef'

Capistrano::Configuration.instance.load do
  namespace :paratrooper do
    namespace :chef do
      set :chef_version, ">= 11.0.0"

      on :load do
        if top.namespaces.key?(:rbenv)
          after "rbenv:setup", "paratrooper:chef:setup"
        elsif top.namespaces.key?(:rvm)
          after "rvm:install_ruby", "paratrooper:chef:setup"
        else
          after "deploy:setup" "paratrooper:chef:setup"
        end
      end

      desc "Installs chef"
      task :setup, :except => { :no_release => true } do
        required_version = fetch(:chef_version).inspect
        installed = capture("gem list -i chef -v #{required_version} || true").strip

        if installed == "false"
          if fetch(:rvm_type, nil) == :user or fetch(:rbenv_path, nil)
            run "gem uninstall -xaI chef || true"
            run "gem install chef -v #{fetch(:chef_version).inspect} --quiet --no-ri --no-rdoc"
            run "gem install ruby-shadow --quiet --no-ri --no-rdoc"

            if fetch(:rbenv_path, nil)
              rbenv.rehash
            end
          else
            sudo "gem uninstall -xaI chef || true"
            sudo "gem install chef -v #{fetch(:chef_version).inspect} --quiet --no-ri --no-rdoc"
            sudo "gem install ruby-shadow --quiet --no-ri --no-rdoc"
          end
        end
      end
    end
  end
end
