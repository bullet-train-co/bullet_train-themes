module ThemeHelper
  def current_theme_object
    @current_theme_object ||= "BulletTrain::Themes::#{current_theme.to_s.classify}::Theme".constantize.new
  end

  def render(options = {}, locals = {}, &block)
    options = BulletTrain::Themes.resolved_partial_path_for(options) || options

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
    body = current_theme_object.find_potential_partial_path_for(options) do |resolved_theme_path|
      if @lookup_context.find_all(resolved_theme_path, [], true, locals.keys).any?
        super(resolved_theme_path, locals, &block)
      end
    # If calling `render` with the updated options is still resulting in a missing template, we need to
    # keep iterating over `directory_order` to work our way up the theme stack and see if we can find the
    # partial there, e.g. going from `light` to `tailwind` to `base`.
    end

    # If we weren't able to find the partial in some theme-based place, then just let the original error bubble up.
    body || raise
  end
end
