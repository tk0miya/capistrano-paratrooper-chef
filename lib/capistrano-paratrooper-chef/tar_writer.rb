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
