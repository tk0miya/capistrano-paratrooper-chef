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

require "rubygems/package"


# Add TarHeader::set_mtime() for hack timestamp
class Gem::Package::TarHeader
  @@mtime = 0

  def self.set_mtime(mtime)
    @@mtime = mtime
  end

  alias :initialize_orig :initialize
  def initialize(vals)
    initialize_orig(vals)
    @mtime = @@mtime
  end
end


# Add TarWriter#add() to append content from path
class TarWriter < Gem::Package::TarWriter
  alias :add_file_orig :add_file
  def add_file(name, mode, mtime, &block)
    Gem::Package::TarHeader.set_mtime(mtime)
    add_file_orig(name, mode, &block)
  end

  alias :mkdir_orig :mkdir
  def mkdir(name, mode, mtime)
    Gem::Package::TarHeader.set_mtime(mtime)
    mkdir_orig(name, mode)
  end

  def add(name)
    stat = File.stat(name)

    if File.directory?(name)
      mkdir(name, stat.mode, stat.mtime)
    else
      add_file(name, stat.mode, stat.mtime) do |file|
        file.write(File.read(name))
      end
    end
  end
end
