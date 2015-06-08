module FeatureToggleService
  class Repository
    DEFAULT_VALUE = nil

    attr_reader :config

    def initialize(config)
      @config    = config
      @overrides = {}
      @cached    = {}
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

    delegate :key_suffix, :enabled?, :app_name, to: :config

    private
    delegate :logger, :cache_toggles?, to: :config

    def load_value(key)
      enabled? ? retrieve_value(key) : default_value_for(key)
    end

    def retrieve_value(key)
      fk = final_key(key)
      etcd_get_toggle(fk)
    rescue Etcd::KeyNotFound => e
      logger.error { "Feature Toggle without key #{key.inspect}, final key #{fk.inspect}." }
      default_value_for(key)
    rescue Errno::ECONNREFUSED => e
      logger.error { "Cannot connect with Feature Toggle Repository! #{key.inspect}, final key #{fk.inspect}." }
      Airbrake.notify(e) if defined?(Airbrake)
      default_value_for(key)
    end

    def etcd_get_toggle(fk)
      etcd_load_toggle(fk) unless cache_toggles?

      @cached.fetch(fk) do
        @cached[fk] = etcd_load_toggle(fk)
      end
    end

    def etcd_load_toggle(fk)
      etcd_client.get(fk).value
    end

    def final_key(key)
      "/v1/toggles/#{app_name}/#{key}/#{key_suffix}"
    end

    def etcd_client
      @etc_client ||= Etcd.client(config.etcd_client)
    end
  end
end