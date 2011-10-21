require 'sinatra'
require 'json'
require 'yaml'

configure do
  config_path = File.dirname(__FILE__) + "/config/deploy.yml"
  config = YAML.load_file(config_path)

  set :port, 3334
  set :app_path, config["app_path"]

end

post '/deploy' do
  received_params = JSON.parse(params[:payload])
  repo_ref = received_params["ref"]

  if repo_ref.include?("tags/homolog")
    `cd #{options.app_path} && git add . && git commit -m "preparing for tag changing" && git checkout master && git pull && git checkout #{repo_ref} && bundle install && rake db:migrate RAILS_ENV=production && init_production`
  end

end

get '/rollback' do
  @tags = `cd #{options.app_path} && git tag`.split("\n")
  erb :rollback
end

post '/rollback_tag' do
  `cd #{options.app_path} && git add . && git commit -m "preparing for tag changing" && git checkout master && git pull && git checkout #{params[:tag_version]} && bundle install && rake db:migrate RAILS_ENV=production && init_production`
  erb :rollback_tag
end

