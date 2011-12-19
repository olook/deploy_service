module DeliveryBus
  class Trigger
    attr_reader :app_servers, :action_type

    def initialize
      config_path  = File.dirname(__FILE__) + '/../../config/deploy.yml'
      config       = YAML.load_file(config_path)
      @app_servers = config['app_servers']
    end

    def pull!(action_type)
      action = process_action(action_type)
      post_to_apps(action)
    end

    def process_action(action_type)
      action = { :action => action_type }
      action.to_json
    end

    def post_to_apps(action)
      @app_servers.each do |app_server|
        Curl::Easy.http_post(app_server, action)
      end
    end
  end
end

