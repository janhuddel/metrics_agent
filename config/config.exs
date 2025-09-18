# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project. If another project (or dependency)
# is using this project as a dependency, the config
# files defined in the other project will have no effect here.

import Config

# Logger configuration - preserve standard_error for production compatibility
config :logger,
  level: if(Mix.env() == :prod, do: :info, else: :debug)

config :logger, :default_handler,
  config: [
    type: :standard_error
  ]

config :logger, :default_formatter,
  format: "$date $time [$level] [$metadata] $message\n",
  metadata: [:module]

# Demo module configuration
config :metrics_agent, :demo,
  enabled: false,
  interval: 1000,
  vendor: "demo"

# Tasmota module configuration
config :metrics_agent, :tasmota,
  enabled: false,
  mqtt_host: "mqtt.intra.rohwer.sh",
  mqtt_port: 1883,
  discovery_topic: "tasmota/discovery/+/config"

# Production-specific configuration
if Mix.env() == :prod do
  # Production config can be overridden by runtime config
  config :metrics_agent, :tasmota,
    mqtt_host: System.get_env("MQTT_HOST", "localhost"),
    mqtt_port: String.to_integer(System.get_env("MQTT_PORT", "1883")),
    discovery_topic: System.get_env("DISCOVERY_TOPIC", "tasmota/discovery/+/config")
end
