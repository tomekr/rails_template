SEED_USER_EMAIL = "user@example.com"
SEED_USER_PASSWORD = "password"

def add_gems
  # Add testing gems
  gem_group :development, :test do
    gem 'rspec-rails'
    gem 'factory_bot_rails'
    gem 'capybara'
    gem 'webdrivers'
    gem 'faker'
  end
  gem 'devise'
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
  say
  say "Switch to your app by running:"
  say "$ cd #{app_name}", :yellow
  say
  say "User seed => #{SEED_USER_EMAIL} / #{SEED_USER_PASSWORD}", :yellow
  say
  say "Then run:"
  say "$ ./bin/dev", :green
end