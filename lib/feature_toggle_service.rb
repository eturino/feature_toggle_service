require 'etcd'
require 'active_support/all'
require 'feature_toggle_service/version'
require 'feature_toggle_service/service'
require 'feature_toggle_service/config'
require 'feature_toggle_service/repository'

module FeatureToggleService

  # Delegation of static methods to the Service instance
  class << self
    delegate :on?, :off?, :config_params, :config_params=,
             :override_on, :override_off, :unset_override, :clear_overrides,
             :default_on, :default_off, :unset_default, :clear_defaults,
             to: :service
  end

  def self.service
    @service ||= Service.new
  end

end
