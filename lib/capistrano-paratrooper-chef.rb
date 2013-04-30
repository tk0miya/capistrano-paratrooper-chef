require "find"
require "json"
require "tempfile"
require "capistrano-paratrooper-chef/tar_writer"
require "capistrano-paratrooper-chef/version"


Capistrano::Configuration.instance.load do
  namespace :paratrooper do
    # directory structure of chef-kitchen
    set :chef_kitchen_path, "config"
    set :chef_default_solo_json_path, "solo.json"
    set :chef_cookbooks_path, ["cookbooks", "site-cookbooks"]
    set :chef_nodes_path, "nodes"
    set :chef_roles_path, "roles"
    set :chef_databags_path, "data_bags"

    # remote chef settings
    set :chef_solo_path, "chef-solo"
    set(:chef_working_dir) {
      capture("echo $HOME").strip + "/chef-solo"
    }
    set :chef_cache_dir, "/var/chef/cache"

    # chef settings
    set :chef_roles_auto_discovery, false
    set :chef_verbose_logging, true
    set :chef_debug, false

    def sudocmd
      envvars = fetch(:default_environment, {}).collect{|k, v| "#{k}=#{v}"}

      begin
        old_sudo = self[:sudo]
        if fetch(:rvm_type, nil) == :user
          self[:sudo] = "rvmsudo_secure_path=1 #{File.join(rvm_bin_path, "rvmsudo")}"
        end

        if envvars
          cmd = "#{top.sudo} env #{envvars.join(" ")}"
        else
          cmd = top.sudo
        end
      ensure
        self[:sudo] = old_sudo  if old_sudo
      end

      cmd
    end

    def sudo(command, *args)
      run "#{sudocmd} #{command}", *args
    end

    def remote_path(*path)
      File.join(fetch(:chef_working_dir), *path)
    end

    def cookbooks_paths
      fetch(:chef_cookbooks_path).collect{|path| File.join(fetch(:chef_kitchen_path), path)}
    end

    def roles_path
      File.join(fetch(:chef_kitchen_path), fetch(:chef_roles_path))
    end

    def role_exists?(name)
      File.exist?(File.join(roles_path, name.to_s + ".json")) ||
      File.exist?(File.join(roles_path, name.to_s + ".rb"))
    end

    def databags_path
      File.join(fetch(:chef_kitchen_path), fetch(:chef_databags_path))
    end

    def nodes_path
      File.join(fetch(:chef_kitchen_path), fetch(:chef_nodes_path))
    end


    namespace :run_list do
      def solo_json_path_for(name)
        path = File.join(nodes_path, name.to_s + ".json")
        if File.exist?(path)
          path
        else
          File.join(fetch(:chef_kitchen_path), fetch(:chef_default_solo_json_path))
        end
      end

      def discover
        find_servers_for_task(current_task).each do |server|
          begin
            open(solo_json_path_for(server.host)) do |fd|
              server.options[:chef_attributes] = JSON.load(fd)

              if server.options[:chef_attributes]["run_list"].nil?
                server.options[:chef_attributes]["run_list"] = []
              end
            end
          rescue JSON::ParserError
            logger.important("Could not parse JSON file: %s" % solo_json_path_for(server.host))
          rescue
            logger.important("Could not read JSON file: %s" % solo_json_path_for(server.host))
          ensure
            if server.options[:chef_attributes].nil?
              server.options[:chef_attributes] = {"run_list" => []}
            end
          end

          if fetch(:chef_roles_auto_discovery)
            role_names_for_host(server).each do |role|
              server.options[:chef_attributes]["run_list"] << "role[#{role}]"  if role_exists?(role)
            end
          end
        end
      end

      def discovered_attributes
        find_servers_for_task(current_task).collect{|server| server.options[:chef_attributes]}.compact
      end

      def discovered_lists
        discovered_attributes.collect{|attr| attr["run_list"]}
      end

      def unique?
        if fetch(:chef_roles_auto_discovery)
          discovered_lists.uniq.size == 1
        else
          true
        end
      end

      def ensure
        if discovered_lists.all?{|run_list| run_list.empty?}
          abort "You must specify at least one recipe or role"
        end
      end
    end

    namespace :chef do
      task :default, :except => { :no_release => true } do
        run_list.discover
        run_list.ensure
        kitchen.ensure_cookbooks
        kitchen.ensure_working_dir
        kitchen.upload
        chef.generate_solo_rb
        chef.generate_solo_json
        chef.execute
      end

      task :solo, :except => { :no_release => true } do
        chef.default
      end

      def generate_solo_rb
        config = <<-CONF
          root = File.expand_path(File.dirname(__FILE__))
          file_cache_path #{fetch(:chef_cache_dir).inspect}
          cookbook_path #{kitchen.cookbooks_paths.inspect}.collect{|dir| File.join(root, dir)}
          role_path File.join(root, #{kitchen.roles_path.inspect})
          data_bag_path File.join(root, #{kitchen.databags_path.inspect})
          verbose_logging #{fetch(:chef_verbose_logging)}
        CONF
        put config, remote_path("solo.rb"), :via => :scp
      end

      def generate_solo_json
        find_servers_for_task(current_task).each do |server|
          put server.options[:chef_attributes].to_json, remote_path("solo.json"), :hosts => server.host, :via => :scp
        end
      end

      desc "Run chef-solo"
      task :execute, :except => { :no_release => true } do
        logger.info "Now running chef-solo"
        command = "#{chef_solo_path} -c #{remote_path("solo.rb")} -j #{remote_path("solo.json")}#{' -l debug' if fetch(:chef_debug)}"
        if run_list.unique?
          sudo command
        else
          parallel do |session|
            session.when "options[:chef_attributes]['run_list'].size > 0",
              "#{sudocmd} #{command}"
          end
        end
      end
    end

    namespace :kitchen do
      namespace :librarian_chef do
        def fetch
          require 'librarian/action'
          require 'librarian/chef'

          if File.exist? 'Cheffile'
            logger.debug("executing librarian-chef")
            Librarian::Action::Resolve.new(librarian_env).run
            Librarian::Action::Install.new(librarian_env).run
          end
        rescue LoadError
          # pass
        end

        def librarian_env
          @librarian_env ||= Librarian::Chef::Environment.new
          @librarian_env.config_db.local["path"] = cookbooks_paths[0]
          @librarian_env
        end
      end

      def ensure_cookbooks
        abort "No cookbooks found in #{fetch(:cookbooks_directory).inspect}" if kitchen.cookbooks_paths.empty?
      end

      def ensure_working_dir
        run "rm -rf #{fetch(:chef_working_dir)} && mkdir -p #{fetch(:chef_working_dir)}"
        sudo "mkdir -p #{fetch(:chef_cache_dir)}"
      end

      desc "Upload files in kitchen"
      task :upload, :except => { :no_release => true } do
        librarian_chef.fetch

        stream = StringIO.new
        TarWriter.new(stream) do |writer|
          kitchen_paths = [cookbooks_paths, roles_path, databags_path].flatten.compact.select{|d| File.exists?(d)}
          Find.find(*kitchen_paths) do |path|
            writer.add(path)
          end
        end

        stream.seek(0)
        put stream.read, remote_path("kitchen.tar"), :via => :scp
        run "cd #{fetch(:chef_working_dir)} && tar -xf kitchen.tar"
      end
    end
  end
end
