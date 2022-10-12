SEED_USER_EMAIL = "user@example.com"
SEED_USER_PASSWORD = "password"

# This allows us to copy_file from the templates directory
def source_paths
  [File.expand_path('templates', __dir__)]
end

def copy_lint_configs
  copy_file ".eslintrc.js"
  copy_file ".erb-lint.yml"
  copy_file ".prettierrc.json"
  copy_file ".rubocop.yml"
end

def setup_postgres
  template "docker-compose.yml.erb", "docker-compose.yml"
  copy_file "Dockerfile"
  template "init.sql.erb", "init.sql"
  template "config/database.yml.erb", "config/database.yml", force: true
end

def start_postgres
  # Start postgres container in background
  run "docker-compose up -d"
end

def add_gems
  # Add testing gems
  gem_group :development, :test do
    gem 'rspec-rails'
    gem 'factory_bot_rails'
    gem 'capybara'
    gem 'webdrivers'
    gem 'faker'
    gem 'rubocop'
  end
  gem 'devise'

  # Remove jbuilder
  gsub_file "Gemfile", /^gem\s+["']jbuilder["'].*$/,''
end

def add_users
  # Install Devise
  generate "devise:install"

  # Configure Devise
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
              env: 'development'

  # Require authentication by default on all controller actions
  insert_into_file "app/controllers/application_controller.rb",
    "\n  before_action :authenticate_user!",
    after: "class ApplicationController < ActionController::Base"

  route "root to: 'home#index'"

  # Create Devise User
  generate :devise, "User"
  
  # Add a user seed to db/seeds.rb after the pre-generated doc comment
  inject_into_file 'db/seeds.rb', after: "movie: movies.first)\n" do <<-RUBY
User.create(email: "#{SEED_USER_EMAIL}", password: "#{SEED_USER_PASSWORD}")
  RUBY
  end
end

initializer 'generators.rb', <<-CODE
  Rails.application.config.generators do |g|
    g.test_framework :rspec,
      fixtures:         false,
      view_specs:       false,
      helper_specs:     false,
      routing_specs:    false,
      controller_specs: false
  end
CODE

add_gems
copy_lint_configs

setup_postgres
start_postgres

after_bundle do
  generate 'rspec:install'
  generate(:controller, "Home index")
  add_users
  
  # Migrate
  rails_command "db:create"
  rails_command "db:migrate"
  rails_command "db:seed"
  
  git :init
  git add: "."
  git commit: %Q{ -m "Initial commit" }
  
  say
  say "Kickoff app successfully created! 👍", :green
  say "Just a heads up, postgres is running in a Docker container in background mode."
  say
  say "Switch to your app by running:"
  say "$ cd #{app_name}", :yellow
  say
  say "User seed => #{SEED_USER_EMAIL} / #{SEED_USER_PASSWORD}", :yellow
  say
  say "Then run:"
  say "$ ./bin/dev", :green
end