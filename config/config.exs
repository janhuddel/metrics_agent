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

# Module configurations are loaded from TOML files at runtime
# See config/runtime.exs and MetricsAgent.ConfigLoader

# Import environment-specific config files
import_config "#{config_env()}.exs"

# Import runtime configuration (always loaded last)
import_config "runtime.exs"
