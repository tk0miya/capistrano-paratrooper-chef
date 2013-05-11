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

if defined?(Capistrano)
  require 'capistrano-paratrooper-chef/chef'
end

require "pathname"
require "capistrano-paratrooper-chef/version"


module Paratrooper
  module Chef
    def self.resource(name, extra_path=nil)
      subdirs = [extra_path, 'default'].compact
      subdirs.each do |path|
        resource = Pathname.new(__FILE__).dirname.join('capistrano-paratrooper-chef/resources', path, name)
        return resource  if File.exists?(resource)
      end

      raise Errno::ENOENT, name
    end
  end
end
