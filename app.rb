require 'sinatra'
require 'json'
require 'yaml'

configure do
  config_path = File.dirname(__FILE__) + "/config/deploy.yml"
  config = YAML.load_file(config_path)

  set :port, 3334
  set :app_path, config["app_path"]
  set :deb_path, config["deb_path"]
  set :bundled_repo_path, config["bundled_repo_path"]
  set :repo_path, config["repo_path"]
  set :deb_pool_path, config["deb_pool_path"]

end

post '/deploy' do
  received_params = JSON.parse(params[:payload])
  repo_ref = received_params["ref"]

  if repo_ref.include?("tags/homolog")
    `cd #{options.app_path} && git add . && git checkout master && git pull && git checkout #{repo_ref} && bundle install && rake db:migrate RAILS_ENV=production && init_unicorn`
  elsif repo_ref.include?("tags/production")
    list_info = "%product olook\n%copyright 2011 by Olook\n%vendor Codeminer42\n%description Olook Web Application\n%license LICENSE\n%readme README.markdown\n%version #{repo_ref[22..45]}\n"

    `cd #{options.bundled_repo_path} && git checkout master && git pull && git checkout #{repo_ref} && \
     cd #{options.deb_path} && rm -f olook.list && \
     echo "#{list_info}" > olook.list && find olook/ -type d -ls | awk '{ print "f 755 root sys /srv/"$11" "$11"/*" }' | grep -v .git | grep -v .svn >> olook.list && \
     epm -f deb -n -a amd64 --output-dir #{options.deb_pool_path} olook && \
     cd #{options.repo_path} && sh -x update_metadata.sh`
  end

end

get '/rollback' do
  @tags = `cd #{options.app_path} && git tag`.split("\n")
  erb :rollback
end

post '/rollback_tag' do
  @tag_version = params[:tag_version]
  `cd #{options.app_path} && git add . && git checkout master && git pull && git checkout #{@tag_version} && bundle install && rake db:drop RAILS_ENV=production && rake db:create RAILS_ENV=production && rake db:migrate RAILS_ENV=production && init_unicorn`
  erb :rollback_tag
end

