module DeliveryBus
  class Deploy
    attr_reader :deb_path, :repo_path, :deb_pool_path, :bundled_repo_path,
                :repo_ref, :deploy_type, :deploy_version
  
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
      manipulate_repo
      create_list_file
      pack_deb
      pull_the_trigger
    end

    private

    def pull_the_trigger
      unless @repo_ref.include?('tags/homolog')
        Trigger.new.pull!('deploy')
      end
    end
  
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
      @deploy_version = @repo_ref[19..45]
    end
  
    def set_production_version
      @deploy_version = @repo_ref[22..45]
    end

    def manipulate_repo
      `cd #{@bundled_repo_path} && git checkout master && git pull && git checkout #{@repo_ref}`
    end

    def create_list_file
      `cd #{@deb_path} && rm -f olook-#{@deploy_type}.list && \
       echo "#{deb_info}" > olook-#{@deploy_type}.list && find olook/ -type d -ls | awk '{ print "f 755 root sys /srv/"$11" "$11"/*" }' | grep -v .git | grep -v .svn >> olook-#{@deploy_type}.list`
    end

    def pack_deb
      `cd #{@deb_path}; epm -f deb -n -a all --output-dir #{@deb_pool_path} olook-#{@deploy_type} && \
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

