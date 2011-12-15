module DeliveryBus
  class Deploy
    attr_reader :deb_path, :repo_path, :deb_pool_path,
                :bundled_repo_path, :repo_ref, :deploy_version
  
    def initialize
      config_path        = File.dirname(__FILE__) + '/../../config/deploy.yml'
      config             = YAML.load_file(config_path)
      @deb_path          = config['deb_path']
      @repo_path         = config['repo_path']
      @deb_pool_path     = config['deb_pool_path']
      @bundled_repo_path = config['bundled_repo_path']
    end
  
    def dispatcher(payload)
      parsed_payload = parse_json(payload)
      @repo_ref = parsed_payload['ref']
      set_deploy_version
      set_deploy_type
      exec_cmd
    end
  
    private

    def set_deploy_type
      if @repo_ref.include?('tags/homolog')
        set_homolog_type
      elsif @repo_ref.include?('tags/production')
        set_production_type
      end
    end

    def set_homolog_type
      @deploy_type = 'homolog'
    end

    def set_production_type
      @deploy_type = 'production'
    end

    def set_deploy_version
      if @repo_ref.include?('tags/homolog')
        set_homolog_version
      elsif @repo_ref.include?('tags/production')
        set_production_version
      end
    end
  
    def set_homolog_version
      @deploy_version = @repo_ref[25..45]
    end
  
    def set_production_version
      @deploy_version = @repo_ref[22..45]
    end
  
    def exec_cmd
      `cd #{@bundled_repo_path} && git checkout master && git pull && git checkout #{@repo_ref} && \
       cd #{@deb_path} && rm -f olook.list && \
       echo "#{deb_info}" > olook.list && find olook/ -type d -ls | awk '{ print "f 755 root sys /srv/"$11" "$11"/*" }' | grep -v .git | grep -v .svn >> olook.list && \
       epm -f deb -n -a amd64 --output-dir #{@deb_pool_path} olook && \
       cd #{@repo_path} && sh -x update_metadata.sh`
    end
  
    def deb_info
      "%product olook-#{@deploy_type}\n%copyright 2011 by Olook\n%vendor Codeminer42\n%description Olook Web Application for #{@deploy_type} environment\n%license LICENSE\n%readme README.markdown\n%version #{@deploy_version}\n"
    end
  
    def parse_json(json)
      JSON.parse(json)
    end
  end
end

