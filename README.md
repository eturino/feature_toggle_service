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

## Config parameters

We can set parameters for config.

* `app_name`: required. It's the App name in hobknob.
* `logger`: logger to be used in the client. Defaults to `nil`
* `logger_level`: if no `logger` is passed, then a new `Logger` will be created to `STDOUT` and this level will be used. Defaults to `nil` 
* `key_suffix`: a suffix on the key, used as the discriminator in hobknob. Can be the environment, or the domain...  Defaults to `nil`
* `enabled`: if false, then etcd calls are skipped, and only overrides and defaults are used. Defaults to `true`
* `etcd_client`: parameters for the etcd client. It's a hash. Defaults to `{ port: 4001 }`

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

Example of configuration in an Rails initializer, using SimpleConfig. We're setting up some config params, and also enabling by default a feature `'my_feature'`

```ruby
require 'feature_toggle_service'

# config
FeatureToggleService.config_params[:enabled]            = SimpleConfig.for(:site).feature_toggle.enabled
FeatureToggleService.config_params[:app_name]           = SimpleConfig.for(:site).feature_toggle.app_name
FeatureToggleService.config_params[:etcd_client][:port] = SimpleConfig.for(:site).feature_toggle.etcd_client.port
FeatureToggleService.config_params[:logger]             = Rails.logger
FeatureToggleService.config_params[:key_suffix]         = Rails.env

# specific defaults on this project
FeatureToggleService.default_on :my_feature
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
