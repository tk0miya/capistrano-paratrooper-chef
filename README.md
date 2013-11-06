# Paratrooper-chef

A capistrano recipe to execute chef-solo in each server.
All of you can use chef-solo remotely without chef-server.

## Installation

Add this line to your application's Gemfile:

    gem 'capistrano-paratrooper-chef'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-paratrooper-chef

## Usage

This recipe will execute chef-solo through paratrooper:chef task.

To setup paratrooper-chef for your application, add following in you config/deploy.rb.

    # in "config/deploy.rb"
    require 'capistrano-paratrooper-chef'

And then, put your chef-kitchen files to config/ directory. 
by default, paratrooper-chef uses following files and directories.

* config/Berksfile
* config/Cheffile
* config/solo.rb
* config/site-cookbooks
* config/roles
* config/environments
* config/data_bags
* config/data_bag_key

Finally, run capistrano with paratrooper:chef task. Then chef-solo runs at remote host.

    $ cap paratrooper:chef


## Setup chef-solo to remote hosts

Paratrooper-chef includes another task to setup chef-solo to remote hosts.
To enable it, add following in your config/deploy.rb.

    # in "config/deploy.rb"
    require "capistrano-paratrooper-chef/omnibus_install"

This recipe will install chef-solo using omnibus-installer during deploy:setup task.

Another way, you want to install chef-solo as gem package, use following lines.

    # in "config/deploy.rb"
    require "capistrano-paratrooper-chef/install"

This recipe will install chef-solo using gem command during deploy:setup task.
Of cource, capistrano-paratrooper-chef/install requires ruby and rubygems are available.

## Define attributes for specific host

Paratrooper-chef supports switching attributes for each host.
Put definition to config/nodes/#{hostname}.json.

If there are no defitions for host, paratrooper-chef uses config/solo.rb as attributes.

## Chef roles Auto discovery

Chef roles auto discovery appends roles of chef to run_list of each host.
To enable auto discovery, set :chef_roles_auto_discovery true (as defualt, it is disabled).

    # in "config/deploy.rb"
    set :chef_roles_auto_discovery, true

This feature makes name-based relations with role of capistrano and chef's one::
* Discovering role definitions of chef from role-names of capistrano that server is assigned
* Run chef with discovered roles at each server
* Be able to play different roles of chef for each server


For example, 'web.example.com' plays :web role:

    set :web, 'web.example.com'

And, there is role defition named 'web.json'.

    # config/roles/web.json
    {
      "nginx" : {
        # ...
      },
      "run_list" : [
        "recipe[nginx]",
      }
    }

Then, paratrooper-chef detects automatically these relation, and append 'role[web]' to run_list of web.example.com .
(do not effect to other hosts)

## Options

Following options are available.

* Settings for remote host

    * `:chef_solo_path` - the path of `chef-solo` command. use `chef-solo` by default (search command from $PATH).
    * `:chef_working_dir` - the path where chef-kitchen should installed. use `$HOME/chef-solo` by default.
    * `:chef_cache_dir` - the path for caches. use `/var/chef/cache` by default.

* Settings for chef and paratrooper

    * `:chef_environment` - environment setting. empty by default.
    * `:chef_roles_auto_discovery` - Enable "Chef roles Auto discovery". use `false` by default.
    * `:chef_verbose_logging`, - Enable verbose logging mode of `chef-solo`. use `true` by default.
    * `:chef_debug` - Enable debug mode of `chef-solo`. use `false` by default.

* Settings for directories

    * `:chef_kitchen_path` - root directory of kitchen. use `config` by default.
    * `:chef_default_solo_json_path` - default attribute file a.k.a solo.json. use `solo.json` by default. 
    * `:chef_cookbooks_path` - cookbooks directory (or list of directories). use `site-cookbooks` by default.
    * `:chef_vendor_cookbooks_path` - cookbooks directory for berkshelf/librarian. use `vendor/cookbooks` by default.
    * `:chef_nodes_path` - nodes directory. use `nodes` by default.
    * `:chef_roles_path` - roles directory. use `roles` by default.
    * `:chef_environment_path` - environments directory. use `environments` by default.
    * `:chef_databags_path` - data bags directory. use `data_bags` by default.
    * `:chef_databag_secret` - path of secret-key for data bags. use `data_bag_key` by default.

## Support recipes

Following recipes work fine with paratrooper-chef.

* rvm-capistrano (https://github.com/wayneeseguin/rvm-capistrano)
* capistrano-rbenv (https://github.com/yyuu/capistrano-rbenv)

## Support cookbook managers

Following cookbook managers work fine with paratrooper-chef.

* berkshelf (http://berkshelf.com/)
* librarian-chef (https://github.com/applicationsonline/librarian-chef)

paratrooper-chef try to fetch cookbooks using these managers.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
