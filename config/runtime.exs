import Config

# Runtime configuration - loaded after all other config files
# This allows for external configuration files to override settings

# Load external config if it exists (for production deployments)
external_config_path = "/etc/metrics-agent/config.exs"

if File.exists?(external_config_path) do
  import_config external_config_path
end

# Additional runtime configuration can be added here
# For example, loading from environment files, etc.
