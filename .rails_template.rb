gem_group :development do
  gem "awesome_print"
  gem "dotenv-rails"
end

# For deploying to Heroku
gem_group :production do
  gem "rails_12factor"
end

# Set the ruby version to match the Gemfile
file ".ruby-version", RUBY_VERSION

# Require ruby version to make Heroku happier (wish this could use version notation)
gsub_file "Gemfile", /^source (.*)$/, %{ruby '#{RUBY_VERSION}'\nsource \\1}

# Set a default Procfile to make Heroku happy
file "Procfile", "web: bundle exec puma -C config/puma.rb"

# Ensure gitignore includes .env
append_file ".gitignore", ".env"

# Location of application asset
APPLICATION_ASSET = "app/assets/stylesheets/application"

assets_exist = File.exists?("app/assets/")

if assets_exist
  # Include bootstrap and the bootstrap generators
  gem "bootstrap-generators", git: "https://github.com/gstark/bootstrap-generators", branch: "includes-simplified-controller-scaffold"

  # Include bootstrap social rails
  gem 'bootstrap-social-rails'

  # And the font awesome rails
  gem 'font-awesome-rails'

  # For jquery UI support
  gem 'jquery-rails'
  gem 'jquery-ui-rails'

  # Use HAML if desired
  haml = false
  if %x{gem list}.include?("haml (")
    haml = yes?("Prefer HAML?")

    # User branch that supports render collection partial
    gem 'haml-rails', github: "gstark/haml-rails", branch: "render-collection" if haml
  end

  # Use SLIM if desired
  slim = false
  if %x{gem list}.include?("slim (")
    slim = yes?("Prefer SLIM?")

    # User branch that supports render collection partial
    gem 'slim-rails' if slim
  end

  # Zap jbuilder because it makes controller scaffolds noisy
  gsub_file "Gemfile", /.*jbuilder.*/, ""

  # Zap coffeescript
  gsub_file "Gemfile", /.*coffee.*/i, ""

  # Change application.css to application.scss
  FileUtils.mv("#{APPLICATION_ASSET}.css", "#{APPLICATION_ASSET}.scss")

  # Buh bye, require_tree and require_self
  gsub_file "app/assets/stylesheets/application.scss", /.*\*= require_.*/, ""
  gsub_file "app/assets/javascripts/application.js", /.*\/\/= require_.*/, ""
  if File.exists?("app/assets/javascripts/cable.js")
    append_file "app/assets/javascripts/application.js", %{//= require 'cable'\n}
  end

  # Add back in jQuery back in for bootstrap support
  append_file "app/assets/javascripts/application.js", "@import 'jquery';"
  append_file "app/assets/javascripts/application.js", "@import 'jquery_ujs';"
end

# Make the schema.rb readonly by default.
# This prevents accidental editing of the schema.rb
# append_file "Rakefile", %{
# task :remove_db_schema_read do
#   path = Rails.root.join("db/schema.rb")
#   if File.exist?(path)
#     File.chmod(0444, path)
#   end
# end
# task :add_db_schema_read do
#   path = Rails.root.join("db/schema.rb")
#   if File.exist?(path)
#     File.chmod(0644, path)
#   end
# end
# Rake::Task["db:schema:dump"].enhance [:add_db_schema_read] do
#   Rake::Task[:remove_db_schema_read].invoke
# end
# }

# Install the bootstrap stuff
after_bundle do
  if assets_exist
    # Blank lines
    append_file "#{APPLICATION_ASSET}.scss", %{\n\n}

    # Import font-awesome
    append_file "#{APPLICATION_ASSET}.scss", %{@import 'font-awesome';\n}

    # Import bootstrap-social
    append_file "#{APPLICATION_ASSET}.scss", %{@import 'bootstrap-social';\n}

    # Import bootstrap generator and variables
    append_file "#{APPLICATION_ASSET}.scss", %{@import 'bootstrap-generators';\n}
    append_file "#{APPLICATION_ASSET}.scss", %{@import 'bootstrap-variables';\n}

    case
    when haml
      generate %{bootstrap:install --template-engine=haml --force}
      FileUtils.rm("app/views/layouts/application.html.erb")
    when slim
      generate %{bootstrap:install --template-engine=slim --force}
      FileUtils.rm("app/views/layouts/application.html.erb")
    else
      generate %{bootstrap:install --stylesheet-engine=scss --force}
    end
  end
end

after_bundle do
  unless %x{which hub}.empty?
    if yes?("Push this repo to github?")
      git add: '.'
      git commit: "-a -m 'Initial commit'"
      run %{hub create}
      run %{git push --set-upstream origin master}
    end
  end
end
