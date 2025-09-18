import Config

# Development-specific configuration

# Logger configuration - more verbose in development
config :logger,
  level: :info

# Module configurations are now loaded from TOML files via ConfigLoader
# Default configurations are defined in config/config.exs
# Runtime configurations are loaded from TOML files in config/runtime.exs
