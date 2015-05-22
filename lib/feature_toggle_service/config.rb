module FeatureToggleService
  class Config

    attr_reader :enabled, :app_name, :etcd_client

    def initialize(enabled: true, app_name:, etcd_client: { port: 4001 })
      @enabled     = enabled
      @app_name    = app_name
      @etcd_client = etcd_client
    end

    def enabled?
      !!enabled
    end
  end
end