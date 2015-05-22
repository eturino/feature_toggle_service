module FeatureToggleService
  class Repository
    DEFAULT_VALUE = nil

    attr_reader :config

    def initialize(config)
      @config    = config
      @overrides = {}
      @defaults  = {}
    end

    def get(key)
      @overrides.fetch(key.to_s) { load_value(key) }
    end

    def default_value_for(key)
      @defaults.fetch(key.to_s, DEFAULT_VALUE)
    end

    def set_override(key, value)
      @overrides[key.to_s] = value
    end

    def unset_override(key)
      @overrides.delete key.to_s
    end

    def clear_overrides
      @overrides.clear
    end

    def set_default(key, value)
      @defaults[key.to_s] = value
    end

    def unset_default(key)
      @defaults.delete key.to_s
    end

    def clear_defaults
      @defaults.clear
    end

    private
    def load_value(key)
      return default_value_for(key) unless config.enabled?

      fk = final_key(key)
      etcd_client.get(fk).value
    rescue Etcd::KeyNotFound => e
      Rails.logger.error "Feature Toggle without key #{key.inspect}, final key #{fk.inspect}."
      default_value_for(key)
    rescue Errno::ECONNREFUSED => e
      Rails.logger.error "Cannot connect with Feature Toggle Repository! #{key.inspect}, final key #{fk.inspect}."
      Airbrake.notify(e)
      default_value_for(key)
    end

    def final_key(key)
      "/v1/toggles/#{config.app_name}/#{key}/#{Rails.env}"
    end

    def etcd_client
      @etc_client ||= Etcd.client(config.etcd_client)
    end
  end
end