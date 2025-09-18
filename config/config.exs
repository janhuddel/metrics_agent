# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project. If another project (or dependency)
# is using this project as a dependency, the config
# files defined in the other project will have no effect here.

import Config

# Logger configuration
config :logger,
  level: :info

config :logger, :default_handler,
  # Ensure all logs are written to STDERR error (STDIN is used for line protocol)
  config: [
    type: :standard_error
  ]

config :logger, :default_formatter,
  format: "$date $time [$level] [$metadata] $message\n",
  metadata: [:module]

# Demo module configuration - defaults
config :metrics_agent, :demo,
  enabled: false,
  interval: 1000,
  vendor: "demo"

# Tasmota module configuration - defaults
config :metrics_agent, :tasmota,
  enabled: false,
  mqtt_host: "localhost",
  mqtt_port: 1883,
  discovery_topic: "tasmota/discovery/+/config"

# Import environment-specific config files
import_config "#{config_env()}.exs"

# Import runtime configuration (always loaded last)
import_config "runtime.exs"
