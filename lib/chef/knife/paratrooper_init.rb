require 'chef/knife'
require 'capistrano-paratrooper-chef'

class Chef
  class Knife
    class ParatrooperInit < Knife
      include FileUtils

      deps do
        require 'fileutils'
      end

      banner "knife paratrooper init DIRECTORY"

      def run
        @base = @name_args.first
        validate!
        mkdir_p @base
        create_kitchen
        create_conffiles
        create_ignorefiles
      end

      def validate!
        if @base.nil?
          show_usage
          ui.fatal "You must specify a directory. Use '.' to initialize the current directory."
          exit 1
        end
      end

      def mkdir_p(*args)
        options = args.last.kind_of?(Hash) ? args.pop : {}

        path = File.join(*args)
        if not File.exist? path
          ui.msg "creating %s/" % path
          FileUtils.mkdir_p(path)

          if options[:keep]
            touch File.join(path, '.keep')
          end
        end
      end

      def create_kitchen
        mkdir_p @base
        mkdir_p @base, "config"

        %w[nodes roles data_bags cookbooks site-cookbooks].each do |subdir|
          mkdir_p @base, 'config', subdir, :keep => true
        end
      end

      def create_conffiles
        %w[Gemfile Capfile config/deploy.rb Cheffile config/solo.json].each do |conffile|
          path = File.join(@base, conffile)
          unless File.exist?(path)
            ui.msg "creating %s" % path
            cp Paratrooper::Chef.resource(File.basename(conffile)), path
          end
        end
      end

      def create_ignorefiles
        %w[.gitignore .hgignore].each do |ignore|
          path = File.join(@base, ignore)
          unless File.exist?(path)
            ui.msg "creating %s" % path
            File.open(path, 'w') do |f|
              f.puts("vendor/bundle/")
              f.puts("config/cookbooks/")
              f.puts("tmp/librarian/")
            end
          end
        end
      end
    end
  end
end
