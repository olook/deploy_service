require 'sinatra'
require 'json'
require 'yaml'

configure do
  config_path = File.dirname(__FILE__) + "/config/deploy.yml"
  config = YAML.load_file(config_path)

  set :app_path, config["app_path"]

end

post '/deploy' do
  received_params = JSON.parse(params[:payload])
  repo_ref = received_params["ref"]

  if repo_ref.include?("tags/homolog")
    `cd #{options.app_path} && cap pull_and_checkout -s ref=#{repo_ref}`
  end

end
