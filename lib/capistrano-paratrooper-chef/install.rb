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

        if installed != "true"
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
