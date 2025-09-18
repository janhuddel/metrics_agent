import Config

# Test-specific configuration

# Logger configuration - minimal logging in tests
config :logger,
  level: :warning

# Demo module configuration - enabled for testing
config :metrics_agent, :demo,
  enabled: true,
  # Faster for tests
  interval: 100,
  vendor: "test-demo"

# Tasmota module configuration - disabled in tests
config :metrics_agent, :tasmota,
  enabled: false,
  mqtt_host: "localhost",
  mqtt_port: 1883,
  discovery_topic: "tasmota/discovery/+/config"
