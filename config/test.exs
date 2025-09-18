import Config

# Test-specific configuration

# Logger configuration - minimal logging in tests
config :logger,
  level: :debug

# Module configurations are now loaded from TOML files via ConfigLoader
# Default configurations are defined in config/config.exs
# Runtime configurations are loaded from TOML files in config/runtime.exs
