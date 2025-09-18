import Config

# Production-specific configuration

# Logger configuration - less verbose in production
config :logger,
  level: :info

# Module configurations are now loaded from TOML files via ConfigLoader
# Default configurations are defined in config/config.exs
# Runtime configurations are loaded from TOML files in config/runtime.exs
