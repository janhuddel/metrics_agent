import Config

# Development-specific configuration

# Logger configuration - more verbose in development
config :logger,
  level: :debug

# Demo module configuration - enabled for development testing
config :metrics_agent, :demo,
  enabled: true,
  interval: 1000,
  vendor: "dev-demo"

# Tasmota module configuration - disabled by default in dev
config :metrics_agent, :tasmota,
  enabled: false,
  mqtt_host: "localhost",
  mqtt_port: 1883,
  discovery_topic: "tasmota/discovery/+/config"
