defmodule MetricsAgent.ConfigLoader do
  @moduledoc """
  Configuration loader for TOML-based configuration files.

  This module handles loading configuration from TOML files and applying
  device-specific overrides. It supports a hierarchical configuration
  structure where global module settings can be overridden for specific devices.
  """

  # Note: We don't use Logger here because it's not configured yet when this module runs

  @config_paths [
    "/etc/metrics-agent/config.toml",
    "config/config.toml",
    "config/config.test.toml"
  ]

  @doc """
  Loads configuration from TOML file and applies it to the application.

  The configuration file should have the following structure:

  ```toml
  [modules.demo]
  enabled = true
  interval = 1000
  vendor = "demo"

  [modules.tasmota]
  enabled = true
  mqtt_host = "localhost"
  mqtt_port = 1883
  discovery_topic = "tasmota/discovery/+/config"

  # Device-specific overrides
  [modules.tasmota.devices."device1"]
  mqtt_host = "192.168.1.100"
  custom_topic = "custom/device1/+/data"
  ```

  ## Default Values

  Each module defines its own default values. If configuration values are not specified in the TOML file,
  the modules will use their internal defaults. See each module's documentation for specific default values.
  """
  def load_config do
    case find_config_file() do
      nil ->
        IO.puts(:stderr, "Warning: No configuration file found, using defaults")
        :ok

      config_path ->
        IO.puts(:stderr, "Loading configuration from #{config_path}")
        load_from_file(config_path)
    end
  end

  @doc """
  Gets configuration for a specific module, optionally for a specific device.
  Automatically applies module defaults if the module implements default_config/0.

  ## Examples

      iex> MetricsAgent.ConfigLoader.get_module_config(:demo)
      %{enabled: true, interval: 1000, vendor: "demo"}

      iex> MetricsAgent.ConfigLoader.get_module_config(:tasmota, "device1")
      %{enabled: true, mqtt_host: "192.168.1.100", ...}
  """
  def get_module_config(module_name, device_id \\ nil) do
    base_config = Application.get_env(:metrics_agent, module_name, [])

    # Apply module defaults if available
    config_with_defaults = apply_module_defaults_if_available(module_name, base_config)

    case device_id do
      nil ->
        config_with_defaults

      device_id ->
        device_overrides = get_device_overrides(module_name, device_id)
        deep_merge(config_with_defaults, device_overrides)
    end
  end

  # Private functions

  defp find_config_file do
    # In test environment, prefer test-specific config
    paths =
      if is_test_environment?() do
        ["config/config.test.toml" | @config_paths]
      else
        @config_paths
      end

    Enum.find(paths, &File.exists?/1)
  end

  # Check if we're in test environment without using Mix (which isn't available in production)
  defp is_test_environment? do
    # Check if we're running tests by looking for test-specific files or environment
    # Check if we're in a test context by looking for test-specific patterns
    File.exists?("config/config.test.toml") or
      System.get_env("MIX_ENV") == "test" or
      case File.cwd() do
        {:ok, cwd} -> String.contains?(cwd, "test")
        _ -> false
      end
  rescue
    _ -> false
  end

  defp load_from_file(config_path) do
    case File.read(config_path) do
      {:ok, content} ->
        case Toml.decode(content) do
          {:ok, config} ->
            apply_config(config)
            :ok

          {:error, reason} ->
            IO.puts(:stderr, "Error: Failed to parse TOML configuration: #{inspect(reason)}")
            {:error, :invalid_toml}
        end

      {:error, reason} ->
        IO.puts(:stderr, "Error: Failed to read configuration file: #{inspect(reason)}")
        {:error, :file_read_error}
    end
  end

  defp apply_config(config) do
    # Apply module configurations
    modules_config = config["modules"] || %{}

    modules_config
    |> Enum.each(fn {module_name, module_config} ->
      module_atom = String.to_atom(module_name)

      # Remove device-specific overrides from base config
      base_config = Map.drop(module_config, ["devices"])

      # Convert string keys to atoms for compatibility
      base_config_atoms = atomize_keys(base_config)

      Application.put_env(:metrics_agent, module_atom, base_config_atoms)

      IO.puts(:stderr, "Applied configuration for module: #{module_name}")
    end)
  end

  defp get_device_overrides(module_name, device_id) do
    config = Application.get_env(:metrics_agent, module_name, [])
    devices = config[:devices] || %{}
    device_config = devices[device_id] || %{}

    atomize_keys(device_config)
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_binary(key) -> {String.to_atom(key), atomize_keys(value)}
      {key, value} -> {key, atomize_keys(value)}
    end)
  end

  defp atomize_keys(value), do: value

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn
      _key, left_val, right_val when is_map(left_val) and is_map(right_val) ->
        deep_merge(left_val, right_val)

      _key, _left_val, right_val ->
        right_val
    end)
  end

  defp deep_merge(_left, right), do: right

  # Apply module defaults if the module implements default_config/0
  defp apply_module_defaults_if_available(module_name, config) do
    module_atom =
      String.to_atom(
        "Elixir.MetricsAgent.Modules.#{String.capitalize(to_string(module_name))}.#{String.capitalize(to_string(module_name))}"
      )

    if Code.ensure_loaded?(module_atom) and function_exported?(module_atom, :default_config, 0) do
      defaults = module_atom.default_config()
      Map.merge(defaults, config)
    else
      config
    end
  rescue
    _ -> config
  end
end
