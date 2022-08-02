require "bullet_train/themes/version"
require "bullet_train/themes/engine"
# require "bullet_train/themes/base/theme"

module BulletTrain
  module Themes
    mattr_accessor :themes, default: {}
    mattr_accessor :logo_height, default: 54

    mattr_reader :partial_paths, default: {}

    # TODO Do we want this to be configurable by downstream applications?
    INVOCATION_PATTERNS = [
      # ❌ This path is included for legacy purposes, but you shouldn't reference partials like this in new code.
      /^account\/shared\//,

      # ✅ This is the correct path to generically reference theme component partials with.
      /^shared\//,
    ]

    def self.theme_invocation_path_for(path)
      # Themes only support `<%= render 'shared/box' ... %>` style calls to `render`, so check `path` is a string first.
      if path.is_a?(String) && (pattern = INVOCATION_PATTERNS.find { _1.match? path })
        path.remove(pattern)
      end
    end

    module Base
      class Theme
        def directory_order
          ["base"]
        end

        def partial_paths_for(path)
          # TODO directory_order should probably come from the `Current` model.
          directory_order.map { "themes/#{_1}/#{path}" }
        end
      end
    end
  end
end
