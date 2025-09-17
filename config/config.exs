# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project. If another project (or dependency)
# is using this project as a dependency, the config
# files defined in the other project will have no effect here.

import Config

config :logger, :default_handler,
  config: [
    type: :standard_error
  ]

config :logger, :default_formatter,
  format: "$date $time [$level] [$metadata] $message\n",
  metadata: [:module]
