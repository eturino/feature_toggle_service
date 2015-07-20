# FeatureToggleService

[![Gem Version](https://badge.fury.io/rb/feature_toggle_service.svg)](http://badge.fury.io/rb/feature_toggle_service)
[![Build Status](https://travis-ci.org/eturino/feature_toggle_service.svg?branch=master)](https://travis-ci.org/eturino/feature_toggle_service)
[![Code Climate](https://codeclimate.com/github/eturino/feature_toggle_service/badges/gpa.svg)](https://codeclimate.com/github/eturino/feature_toggle_service)
[![Test Coverage](https://codeclimate.com/github/eturino/feature_toggle_service/badges/coverage.svg)](https://codeclimate.com/github/eturino/feature_toggle_service/coverage)

A client for Feature Toggles. It uses [hobknob](https://github.com/opentable/hobknob) and [etcd](https://github.com/coreos/etcd) as data source.

It also supports overrides and defaults.

note: if Airbrake is defined and etcd is not reachable, it `Airbrake.notify(exception)` will be called, where `exception` is the `Errno::ECONNREFUSED` error.

## Basic use

We use `on?` and `off?` methods, to check if a feature is enabled or disabled in hobknob. We use a simple String or Symbol as the key. It performs a `to_s` to the key so using `:feature` or `'feature'` is the same.

```ruby

if FeatureToggleService.on? :my_feature
  do_something_that_needs_my_feature
end

if FeatureToggleService.off? 'other_feature'
  do_something_that_assumes_other_feature_is_not_enabled
end

```

## Override

If an override is set, either ON or OFF, then we don't look into etcd, and we return the override value directly.
 
An override is set to ON with `FeatureToggleService.override_on(key)`, and to OFF with `FeatureToggleService.override_off(key)`.
 
We can remove an override with `FeatureToggleService.unset_override(key)`, or all of hem with `FeatureToggleService.clear_override`.


## Default

If there is no override for the given key, and it's not set in hobknob to either ON or OFF, then the default value is used. By default, the default value is `nil` which count as falsey.
 
A default is set to ON with `FeatureToggleService.default_on(key)`, and to OFF with `FeatureToggleService.default_off(key)`.
 
We can remove a default with `FeatureToggleService.unset_default(key)`, or all of hem with `FeatureToggleService.clear_default`.

The default value will be returned if the key is not found in hobknob, or if etcd does not respond.

## Cached Toggles

If enabled in the config params (see "Config parameters" section bellow), a given toggle will be loaded only once, and its value will be stored in the FeatureToggleService in a hash.

The caching takes place around the actual call to `etcd` so it's the only part that is cached. It's only cached if it is successful (true or false), so if etcd is off or if the key is not found it will keep checking etcd every time. 

## Config parameters

We can set parameters for config.

* `app_name`: required. It's the App name in hobknob.
* `cache_toggles`: if true, the toggles will be looked up only once (see "Cached Toggles" section). It's a boolean. Defaults to `false`
* `logger`: logger to be used in the client. Defaults to `nil`
* `logger_level`: if no `logger` is passed, then a new `Logger` will be created to `STDOUT` and this level will be used. Defaults to `nil` 
* `key_suffix`: a suffix on the key, used as the discriminator in hobknob. Can be the environment, or the domain...  Defaults to `nil`
* `enabled`: if false, then etcd calls are skipped, and only overrides and defaults are used. Defaults to `true`
* `etcd_client`: parameters for the etcd client. It's a hash. Defaults to `{ port: 4001, host: 'localhost' }`

*important: The config has to be set before using the service*

We can set the configs with `FeatureToggleService.config_params[:enabled] = true`.

 
## Example

if in Rails, this would be in an initializer. This example sets the config from SimpleConfig.

```ruby
require 'feature_toggle_service'

# config
FeatureToggleService.config_params[:enabled]            = SimpleConfig.for(:site).feature_toggle.enabled
FeatureToggleService.config_params[:app_name]           = SimpleConfig.for(:site).feature_toggle.app_name
FeatureToggleService.config_params[:etcd_client][:port] = SimpleConfig.for(:site).feature_toggle.etcd_client.port
FeatureToggleService.config_params[:logger]             = Rails.logger
FeatureToggleService.config_params[:key_suffix]         = Rails.env

# specific defaults on this project
FeatureToggleService.default_on :one_feature
FeatureToggleService.default_off :another_feature

# specific overrides on this project
FeatureToggleService.override_on :third_feature
FeatureToggleService.override_off 'other_stuff'
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'feature_toggle_service'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install feature_toggle_service

## Usage

### Setup

Example of configuration in an Rails initializer. We're setting up some config params, and also enabling by default a feature `'my_feature'`


First, we add common config to the Application config, like where do we have our etcd repository and how to access it.

```ruby
# config/application.rb

module MyCoolProject
  class Application < Rails::Application

    #... other stuff

    # FEATURE TOGGLE
    config.feature_toggle                       = ActiveSupport::OrderedOptions.new
    config.feature_toggle.enabled               = true
    config.feature_toggle.cache_toggles         = true
    config.feature_toggle.app_name              = 'MyCoolProject'
    config.feature_toggle.etcd_client           = ActiveSupport::OrderedOptions.new
    config.feature_toggle.etcd_client.host      = 'etcd.example.org'
    config.feature_toggle.etcd_client.port      = 443
    config.feature_toggle.etcd_client.use_ssl   = true
    config.feature_toggle.etcd_client.user_name = 'my-basic-auth-username'
    config.feature_toggle.etcd_client.password  = 'my-basic-auth-password'
  end
end
```

Then we add environment keys, overrides and defaults on the env config

```ruby
# config/environments/mcp_int.rb

MyCoolProject::Application.configure do

  # FEATURED TOGGLES
  config.feature_toggle.key_suffix   = 'int'
  config.feature_toggle.default_on   = [:feature_1, :another_feature]
  config.feature_toggle.default_off  = []
  config.feature_toggle.override_on  = [:feature_3]
  config.feature_toggle.override_off = []
end

```

Finally, we load the config into `FeatureToggleService` in the initializer:

```ruby
# config/initializers/feature_toggles.rb

require 'feature_toggle_service'

# config
ftc = Rails.configuration.feature_toggle
cp  = FeatureToggleService.config_params

cp[:logger]        = Rails.logger
cp[:cache_toggles] = ftc.cache_toggles unless ftc.cache_toggles.nil?
cp[:enabled]       = ftc.enabled unless ftc.enabled.nil?
cp[:app_name]      = ftc.app_name unless ftc.app_name.nil?
cp[:key_suffix]    = ftc.key_suffix unless ftc.key_suffix.nil?

etcd_cnf = ftc.etcd_client
if etcd_cnf
  cp[:etcd_client][:host]      = etcd_cnf.host unless etcd_cnf.host.nil?
  cp[:etcd_client][:port]      = etcd_cnf.port unless etcd_cnf.port.nil?
  cp[:etcd_client][:use_ssl]   = etcd_cnf.use_ssl unless etcd_cnf.use_ssl.nil?
  cp[:etcd_client][:user_name] = etcd_cnf.user_name unless etcd_cnf.user_name.nil?
  cp[:etcd_client][:password]  = etcd_cnf.password unless etcd_cnf.password.nil?
end

# specific defaults on this project
Array(ftc.default_on).each do |key|
  FeatureToggleService.default_on key
end

Array(ftc.default_off).each do |key|
  FeatureToggleService.default_off key
end

Array(ftc.override_on).each do |key|
  FeatureToggleService.override_on key
end

Array(ftc.override_off).each do |key|
  FeatureToggleService.override_off key
end
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/eturino/feature_toggle_service/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
