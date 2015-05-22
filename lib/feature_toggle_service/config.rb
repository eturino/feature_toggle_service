module FeatureToggleService
  class Config

    attr_reader :enabled, :app_name, :etcd_client, :logger, :key_suffix

    def initialize(logger: nil, logger_level: nil, key_suffix: 'suffix', enabled: true, app_name:, etcd_client: { port: 4001 })
      @enabled     = enabled
      @app_name    = app_name
      @etcd_client = etcd_client
      @key_suffix  = key_suffix
      @logger      = logger || build_logger(logger_level)
    end

    def enabled?
      !!enabled
    end

    private
    def build_logger(logger_level)
      Logger.new(STDOUT).tap do |log|
        log.level = logger_level if logger_level.present?
      end
    end
  end
end