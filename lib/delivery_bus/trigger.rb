# -*- encoding: utf-8 -*-
module DeliveryBus
  class Trigger
    attr_reader :app_servers

    def initialize
      config_path  = File.dirname(__FILE__) + '/../../config/deploy.yml'
      config       = YAML.load_file(config_path)
      @app_servers = config['app_servers']
    end

    def pull!(action_type)
      process_action(action_type)
    end

    def process_action(action_type)
      @app_servers.each do |server_address, seconds|
        action_json = { :type => action_type, :date => Time.now + seconds.to_i }.to_json
        send_package(server_address, action_json)
      end
    end

    def send_package(server_address, json)
      Curl::Easy.http_post(server_address, json)
    end
  end
end
