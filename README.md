# rails_template

Basic Rails 7 template for starting a new project with RSpec and Devise.

## Usage

```
rails new --css tailwind -T -m https://raw.githubusercontent.com/tomekr/rails_template/main/template.rb [app_name]
```

## What this sets up

- Dockerized Postgres
- Linters
  - erblint
  - eslint
  - prettier
  - rubocop
- rspec+factorybot configs
- Devise with a seed user
