# -*- coding: utf-8 -*-
#  Copyright 2012 Takeshi KOMIYA
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

require 'capistrano-paratrooper-chef'

Capistrano::Configuration.instance.load do
  namespace :paratrooper do
    namespace :chef do
      set :chef_solo_path, "/opt/chef/bin/chef-solo"

      desc "Installs chef (by omnibus installer)"
      task :install_omnibus_chef do
        if capture("command -v curl || true").strip.empty?
          run "wget -O - http://www.opscode.com/chef/install.sh | #{top.sudo if fetch(:chef_use_sudo)} bash"
        else
          run "curl -L http://www.opscode.com/chef/install.sh | #{top.sudo if fetch(:chef_use_sudo)} bash"
        end
      end
      after "deploy:setup", "paratrooper:chef:install_omnibus_chef"
    end
  end
end
