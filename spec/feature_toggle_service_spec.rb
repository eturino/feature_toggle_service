require 'spec_helper'

describe FeatureToggleService do
  it 'has a version number' do
    expect(FeatureToggleService::VERSION).not_to be nil
  end

  let(:key) { 'my_key' }

  let(:config_enabled) { true }
  let(:app_name) { 'my-app' }
  let(:key_suffix) { 'test' }
  let(:etcd_client_port) { 4040 }
  let(:logger) { Naught.build.new }

  let(:final_key) { "/v1/toggles/#{app_name}/#{key}/#{key_suffix}" }
  let(:etcd_key_path) { "/v2/keys#{final_key}" }

  let(:etcd_complete_path) { "127.0.0.1:#{etcd_client_port}#{etcd_key_path}" }

  let(:etcd_body_404) do
    <<-ETCD
{"errorCode":100,"message":"Key not found","cause":"#{final_key}","index":86}
    ETCD
  end

  let(:etcd_body_200) do
    <<-ETCD
{"action":"get","node":{"key":"#{final_key}","value":"#{value}","modifiedIndex":73,"createdIndex":73}}
    ETCD
  end

  before(:each) do
    # Etcd::Log.level = Logger::INFO

    WebMock.reset!

    FeatureToggleService.reload_service

    FeatureToggleService.config_params[:enabled]            = config_enabled
    FeatureToggleService.config_params[:app_name]           = app_name
    FeatureToggleService.config_params[:etcd_client][:port] = etcd_client_port
    FeatureToggleService.config_params[:logger_level]       = Logger::INFO
    FeatureToggleService.config_params[:key_suffix]         = key_suffix

    FeatureToggleService.clear_overrides
    FeatureToggleService.clear_defaults
  end

  describe '.enabled?' do

    context 'with etcd disabled' do
      let(:config_enabled) { false }

      it do
        expect(FeatureToggleService.enabled?).to be_falsey
      end
    end


    context 'with etcd enabled' do
      let(:config_enabled) { true }

      it do
        expect(FeatureToggleService.enabled?).to be_truthy
      end
    end
  end

  describe '.on?' do
    context 'true in etcd' do
      let(:value) { true }
      before(:each) do
        stub_request(:get, etcd_complete_path).to_return(body: etcd_body_200)
      end

      context 'alone' do
        it do
          expect(FeatureToggleService.on? key).to be_truthy
        end
      end

      context 'with etcd disabled' do
        let(:config_enabled) { false }

        it do
          expect(FeatureToggleService.on? key).to be_falsey
        end
      end

      context 'with false default' do
        before(:each) do
          FeatureToggleService.default_off key
        end

        it do
          expect(FeatureToggleService.on? key).to be_truthy
        end
      end

      context 'with true default' do
        before(:each) do
          FeatureToggleService.default_on key
        end

        it do
          expect(FeatureToggleService.on? key).to be_truthy
        end
      end

      context 'with false override' do
        before(:each) do
          FeatureToggleService.override_off key
        end

        it do
          expect(FeatureToggleService.on? key).to be_falsey
        end
      end

      context 'with true override' do
        before(:each) do
          FeatureToggleService.override_on key
        end

        it do
          expect(FeatureToggleService.on? key).to be_truthy
        end
      end

    end

    context 'false in etcd' do
      let(:value) { false }
      before(:each) do
        stub_request(:get, etcd_complete_path).to_return(body: etcd_body_200)
      end

      context 'alone' do
        it 'returns false' do
          expect(FeatureToggleService.on? key).to be_falsey
        end
      end

      context 'with false default' do
        before(:each) do
          FeatureToggleService.default_off key
        end

        it do
          expect(FeatureToggleService.on? key).to be_falsey
        end
      end

      context 'with true default' do
        before(:each) do
          FeatureToggleService.default_on key
        end

        it do
          expect(FeatureToggleService.on? key).to be_falsey
        end
      end

      context 'with false override' do
        before(:each) do
          FeatureToggleService.override_off key
        end

        it do
          expect(FeatureToggleService.on? key).to be_falsey
        end
      end

      context 'with true override' do
        before(:each) do
          FeatureToggleService.override_on key
        end

        it do
          expect(FeatureToggleService.on? key).to be_truthy
        end
      end

    end

    context 'not set in etcd' do
      before(:each) do
        stub_request(:get, etcd_complete_path).to_return(body: etcd_body_404, status: 404)
      end

      context 'alone' do
        it do
          expect(FeatureToggleService.on? key).to be_falsey
        end
      end

      context 'with false default' do
        before(:each) do
          FeatureToggleService.default_off key
        end

        it do
          expect(FeatureToggleService.on? key).to be_falsey
        end
      end

      context 'with true default' do
        before(:each) do
          FeatureToggleService.default_on key
        end

        it do
          expect(FeatureToggleService.on? key).to be_truthy
        end
      end

      context 'with false override' do
        before(:each) do
          FeatureToggleService.override_off key
        end

        it do
          expect(FeatureToggleService.on? key).to be_falsey
        end
      end

      context 'with true override' do
        before(:each) do
          FeatureToggleService.override_on key
        end

        it do
          expect(FeatureToggleService.on? key).to be_truthy
        end
      end

    end
  end

  describe '.off?' do
    before(:each) do
      stub_request(:get, etcd_complete_path).to_return(body: etcd_body_404, status: 404)
      FeatureToggleService.unset_override key
      FeatureToggleService.unset_default key
    end

    context 'returns reverse of on?' do
      it 'works with override on' do
        # using override
        FeatureToggleService.override_on key
        expect(FeatureToggleService.on? key).to be_truthy
        expect(FeatureToggleService.off? key).to be_falsey
      end

      it 'works with override off' do
        FeatureToggleService.override_off key
        expect(FeatureToggleService.on? key).to be_falsey
        expect(FeatureToggleService.off? key).to be_truthy
      end

      it 'works with default on' do
        # using defaults
        FeatureToggleService.default_on key
        expect(FeatureToggleService.on? key).to be_truthy
        expect(FeatureToggleService.off? key).to be_falsey
      end

      it 'works with default off' do
        FeatureToggleService.default_off key
        expect(FeatureToggleService.on? key).to be_falsey
        expect(FeatureToggleService.off? key).to be_truthy
      end

      context 'based on etcd' do
        before(:each) do
          stub_request(:get, etcd_complete_path).to_return(body: etcd_body_200)
        end

        context 'TRUE' do
          let(:value) { true }
          it do
            expect(FeatureToggleService.on? key).to be_truthy
            expect(FeatureToggleService.off? key).to be_falsey
          end
        end

        context 'FALSE' do
          let(:value) { false }
          it do
            expect(FeatureToggleService.on? key).to be_falsey
            expect(FeatureToggleService.off? key).to be_truthy
          end
        end
      end
    end

  end
end
