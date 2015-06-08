module FeatureToggleService
  class Service

    FALSE_VALUES = [:false, 'false', false, 0]
    TRUE_VALUES  = [:true, 'true', true, 1]

    # Instance
    def config_params
      @config_params ||= { key_suffix: 'suffix', enabled: true, cache_toggles: false, app_name: 'Default App', etcd_client: { port: 4001 } }
    end

    def off?(key)
      !on? key
    end

    def on?(key)
      case repository.get(key)
      when *TRUE_VALUES
        true
      else
        false
      end
    end

    # FOR TESTS, DEFAULTS and OVERRIDES
    delegate :unset_override, :clear_overrides, :unset_default, :clear_defaults, to: :repository

    # check if ETCD is enabled or not
    delegate :enabled?, :logger, to: :config

    # helper methods
    def default_on(key)
      logger.info "FeaturedToggleService: default ON for key: #{key}"
      repository.set_default key, true
    end

    def default_off(key)
      logger.info "FeaturedToggleService: default OFF for key: #{key}"
      repository.set_default key, false
    end

    def override_on(key)
      logger.info "FeaturedToggleService: override ON for key: #{key}"
      repository.set_override key, true
    end

    def override_off(key)
      logger.info "FeaturedToggleService: override OFF for key: #{key}"
      repository.set_override key, false
    end

    def config
      @config ||= Config.new config_params
    end

    private
    def repository
      @repository ||= Repository.new config
    end
  end
end