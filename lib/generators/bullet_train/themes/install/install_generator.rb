# frozen_string_literal: true

require "rails/generators"
require "rails/generators/actions"

require 'colorize'

module BulletTrain
  module Themes
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Create bin/open-theme-partial"

      def add_open_theme_partial
        puts("Creating open-theme-partial inside bin/ folder\n")

        file_name = "bin/open-theme"

        copy_file(file_name, file_name)

        # change permission of the file so that user has permission to run the shell script
        system("chmod u+x #{file_name}")
      end
    end
  end
end
