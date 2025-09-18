import Config

# Runtime configuration - loaded after all other config files
# Note: import_config/1 is not allowed in runtime.exs for security reasons
# External configuration is now handled via TOML files

# Load TOML configuration if available
if Code.ensure_loaded?(MetricsAgent.ConfigLoader) do
  case MetricsAgent.ConfigLoader.load_config() do
    :ok ->
      :ok

    {:error, reason} ->
      IO.warn("Failed to load TOML configuration: #{inspect(reason)}")
  end
end
