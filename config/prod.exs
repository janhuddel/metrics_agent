import Config

# Production-specific configuration

# Logger configuration - less verbose in production
config :logger,
  level: :info

# Demo module configuration - controlled by environment variables
config :metrics_agent, :demo,
  enabled: System.get_env("DEMO_ENABLED", "false") == "true",
  interval: String.to_integer(System.get_env("DEMO_INTERVAL", "1000")),
  vendor: System.get_env("DEMO_VENDOR", "demo")

# Tasmota module configuration - controlled by environment variables
config :metrics_agent, :tasmota,
  enabled: System.get_env("TASMOTA_ENABLED", "true") == "true",
  mqtt_host: System.get_env("MQTT_HOST", "localhost"),
  mqtt_port: String.to_integer(System.get_env("MQTT_PORT", "1883")),
  discovery_topic: System.get_env("DISCOVERY_TOPIC", "tasmota/discovery/+/config")
