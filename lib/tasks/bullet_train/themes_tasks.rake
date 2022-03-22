namespace :bullet_train do
  namespace :themes do

    # TODO: This only searches for partials in Bullet Train theme-related gem.
    # Make this search the other gems as well.
    desc "Points to and opens the corresponding theme partial"
    task :open, ['theme', 'partial'] => :environment do |task, args|
      if args.to_a.empty?
        puts "Write the theme and the partial you're looking for:"
        puts "i.e. - `rake bullet_train:themes:open[base,shared/fields/text_field]`"
      elsif args.to_a.size < 2
        puts "Please specify both a theme and a partial".red
      else
        literal_partial_path = convert_to_literal_partial(args[:partial])
        resolved_partial = nil

        ThemeHelper::INVOCATION_PATTERNS.each do |pattern|
          next unless literal_partial_path.match(/^#{pattern}/)

          partial_without_hierarchy_base = remove_hierarchy_base(literal_partial_path, pattern)
          resolved_partial = get_full_debased_file_path(partial_without_hierarchy_base, args[:theme])

          bullet_train_gems = []
          File.open("#{Rails.root}/Gemfile.lock") do |file|
            file.each_line do |line|
              bullet_train_gems << line if line.match?(/(bullet_train).*\([0-9|\.]+\)$/)
            end
          end

          # TODO: This finds any themes namespaced as `bullet_train-themes-#{theme_name}`, but not custom themes inside `bullet_train`.
          # If developers are making their own themes, do we need to bother searching for them if the developer knows where they are already?
          gem = bullet_train_gems.select {|bt_gem| bt_gem.match?("bullet_train-themes-#{args[:theme]}")}.first
          gem ||= bullet_train_gems.select {|bt_gem| bt_gem.match?(/bullet_train-themes\s/)}.first # Use base themes gem if the partial is not under a particular theme
          gem_path = gem.strip.sub(/\s/, "-").gsub(/(\()([0-9|\.]+)(\))/, '\2')
          gem_path = "#{Gem.paths.home}/gems/#{gem_path}/"
          full_resolved_partial = gem_path + resolved_partial
          if File.exists?(gem_path)
            puts "#{args[:partial]} resolves to " + "#{full_resolved_partial}.".green
            begin
              open_file_in_editor(full_resolved_partial)
            rescue Errno::ENOENT => _
              puts "Could not open file.".red
            end
            break
          end
        end
      end
    end
  end
end

# i.e. Changes "account/shared/box" to "account/shared/_box"
def convert_to_literal_partial(path)
  path.sub(/.*\K\//, "/_")
end

# i.e. Changes "account/shared/_box" to "_box"
def remove_hierarchy_base(path, pattern)
  path.gsub(pattern, "")
end

# i.e. Get "app/views/themes/light/_box.html.erb" from "_box"
def get_full_debased_file_path(path, theme_directory)
  "app/views/themes/#{theme_directory}/#{path}.html.erb"
end

# Adds a hierarchy with a specific theme to a partial.
# i.e. Changes "workflow/box" to "themes/light/workflow/box"
def add_hierarchy_to_path(file_path, theme_directory)
  "themes/#{theme_directory}/#{file_path}"
end

def open_file_in_editor(file)
  if Gem::Platform.local.os == "linux"
    `xdg-open #{file}`
  else
    `open #{file}`
  end
end
