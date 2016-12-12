# Include bootstrap and the bootstrap generators
gem "bootstrap-generators", git: "https://github.com/gstark/bootstrap-generators", branch: "includes-simplified-controller-scaffold"

# Include bootstrap social rails
gem 'bootstrap-social-rails'

# And the font awesome rails
gem 'font-awesome-rails'

# For jquery UI support
gem 'jquery-ui-rails'

# Use HAML if desired
haml = yes?("Prefer HAML?")
gem 'haml-rails' if haml

gem_group :development do
  gem "dotenv-rails"
end

# For deploying to Heroku
gem_group :production do
  gem "rails_12factor"
end

# Zap jbuilder because it makes controller scaffolds noisy
gsub_file "Gemfile", /.*jbuilder.*/, ""

# Location of application asset
APPLICATION_ASSET = "app/assets/stylesheets/application"

# Change application.css to application.scss
FileUtils.mv("#{APPLICATION_ASSET}.css", "#{APPLICATION_ASSET}.scss")

# Require ruby 2.3.1 to make Heroku happier (wish this could use version notation)
gsub_file "Gemfile", /^source (.*)$/, %{ruby '#{RUBY_VERSION}'\nsource \\1}

# Set a default Procfile to make Heroku happy
file "Procfile", "web: bundle exec puma -C config/puma.rb"

# Install the bootstrap stuff
after_bundle do
  # Blank lines
  append_file "#{APPLICATION_ASSET}.scss", %{\n\n}

  # Import font-awesome
  append_file "#{APPLICATION_ASSET}.scss", %{@import 'font-awesome';\n}

  # Import bootstrap-social
  append_file "#{APPLICATION_ASSET}.scss", %{@import 'bootstrap-social';\n}

  if haml
    generate %{bootstrap:install --template-engine=haml --force}
    FileUtils.rm("app/views/layouts/application.html.erb")
  else
    generate %{bootstrap:install --stylesheet-engine=scss --force}
  end
end

after_bundle do
  if yes?("Create Git repo?")
    git :init
    git add: '.'
    git commit: "-a -m 'Initial commit'"
    unless %x{which hub}.empty?
      if yes?("Push this repo to github?")
        run %{hub create}
        run %{git push --set-upstream origin master}
      end
    end
  end
end