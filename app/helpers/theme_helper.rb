module ThemeHelper
  def current_theme_object
    @current_theme_object ||= "BulletTrain::Themes::#{current_theme.to_s.classify}::Theme".constantize.new
  end

  def render(options = {}, locals = {}, &block)
    # The theme engine only supports `<%= render 'shared/box' ... %>` style calls to `render`.
    return super unless options.is_a?(String)

    # TODO This caching should be disabled in development so new templates are taken into account without restarting the server.
    options = BulletTrain::Themes.partial_paths[options] || options

    # This is where we try to just lean on Rails default behavior. If someone renders `shared/box` and also has a
    # `app/views/shared/_box.html.erb`, then no error will be thrown and we will have never interfered in the normal
    # Rails behavior.
    #
    # We also don't do anything special if someone renders `shared/box` and we've already previously resolved that
    # partial to be served from `themes/light/box`. In that case, we've already replaced `shared/box` with the
    # actual path of the partial, and Rails will do the right thing from this point.
    #
    # However, if one of those two situations isn't true, then this call here will throw an exception and we can
    # perform the appropriate magic to figure out where amongst the themes the partial should be rendering from.
    super
  rescue ActionView::MissingTemplate
    if requested_partial = BulletTrain::Themes.possible_theme_render_path(options)
      original_options = options

      paths = current_theme_object.partial_paths_for(requested_partial)
      paths.each do |theme_path|
        options = theme_path

        # Try rendering the partial again with the updated options.
        body = super

        # 🏆 If we get this far, then we've found the actual path of the theme partial. We should cache it!
        BulletTrain::Themes.partial_paths[original_options] = options

        # We also need to return whatever the rendered body was.
        return body

      # If calling `render` with the updated options is still resulting in a missing template, we need to
      # keep iterating over `directory_order` to work our way up the theme stack and see if we can find the
      # partial there, e.g. going from `light` to `tailwind` to `base`.
      rescue ActionView::MissingTemplate
        next
      end
    end

    # If we weren't able to find the partial in some theme-based place, then just let the original error bubble up.
    raise
  end
end
