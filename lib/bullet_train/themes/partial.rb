require 'fileutils'
require 'colorize'

require_relative '../../../app/helpers/theme_helper'
require_relative '../../theme_partials'

module BulletTrain
  module Themes
    class Partial
      include ThemeHelper
      include ThemePartials

      def initialize(argv)
        @partial_path = argv[0]
        @literal_partial_path = convert_to_literal_partial(argv[0])
        @resolved_partial = nil
      end

      def open
        puts("Your current theme: #{current_theme}\n\n")

        find_and_set_resolved_partial_path

        if partial_file_exists?
          open_partial
        else
          print_partial_not_found_message
        end
      end

      private

      attr_reader :literal_partial_path, :partial_path
      attr_accessor :resolved_partial

      def inform(message)
        puts(message.yellow)
      end

      def inform_success(message)
        puts(message.green)
      end

      def print_error(message)
        puts(message.red)
      end

      def partial_file_exists?
        return if resolved_partial.blank?

        File.exist?(resolved_partial)
      end

      def partial_full_debased_file_path(theme, include_target)
        partial_without_hierarchy_base = remove_hierarchy_base(literal_partial_path, include_target)

        theme_directory = literal_partial_path.match(/^shared\/fields/) ? "base" : theme

        # shared/fields are framework-agnostic, so we always pull them from the base directory.
        get_full_debased_file_path(partial_without_hierarchy_base, theme_directory)
      end

      def find_and_set_resolved_partial_path
        THEME_DIRECTORY_ORDER.each do |theme|
          INCLUDE_TARGETS.each do |include_target|
            next unless literal_partial_path.match(/^#{include_target}/)

            @resolved_partial = partial_full_debased_file_path(theme, include_target)

            break if partial_file_exists?
          end

          break if partial_file_exists?
        end
      end

      def print_partial_not_found_message
        print_error("Sorry, we couldn't find the partial which corresponds to `#{partial_path}`.")
        print_error("Please check the path you are trying to resolve and try again.\n\n")

        inform("Hint: Does the file already exist in the directory you're trying to resolve?")
        puts("Check the path and see if it's already being rendered directly from the partial in question.")
      end

      def open_partial
        inform_success("#{partial_path} resolves to " + "#{resolved_partial}.")

        sleep(1)

        exec("open #{resolved_partial}")
      rescue Errno::ENOENT => _e
        print_error("Could not open file.")
      end
    end
  end
end
