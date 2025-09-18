# Adding a New Module - Example

This document demonstrates how easy it is to add a new module with the generic ModuleSupervisor approach.

## Step 1: Create the Module Implementation

Create a new module file, e.g., `lib/metrics_agent/modules/prometheus/prometheus.ex`:

```elixir
defmodule MetricsAgent.Modules.Prometheus.Prometheus do
  @moduledoc """
  Prometheus module for collecting metrics from Prometheus endpoints.
  """

  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Returns the default configuration for the Prometheus module.
  """
  def default_config do
    %{
      enabled: false,
      interval: 30000,
      endpoint: "http://localhost:9090/metrics"
    }
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting Prometheus module")
    
    config = MetricsAgent.ConfigLoader.get_module_config(:prometheus)
    
    # ConfigLoader automatically applies defaults, so we can use config directly
    interval = config[:interval]
    endpoint = config[:endpoint]
    
    # Schedule first metric collection
    Process.send_after(self(), :collect_metrics, interval)
    
    {:ok, %{config: config, interval: interval, endpoint: endpoint}}
  end

  @impl true
  def handle_info(:collect_metrics, state) do
    # Collect metrics from Prometheus endpoint
    # ... implementation details ...
    
    # Schedule next collection
    Process.send_after(self(), :collect_metrics, state.interval)
    
    {:noreply, state}
  end
end
```

## Step 2: Add Configuration

The module defines its own defaults via the `default_config/0` function. 
You only need to add runtime configuration to `/etc/metrics-agent/config.toml`:

```toml
# /etc/metrics-agent/config.toml - Runtime configuration
[modules.prometheus]
enabled = true
interval = 30000
endpoint = "http://localhost:9090/metrics"

# Device-specific overrides
[modules.prometheus.devices."server1"]
endpoint = "http://192.168.1.10:9090/metrics"
interval = 15000
```

**Note**: The `default_config/0` function provides the default values, so you only need to specify values you want to override in the TOML file.

## Step 3: Register the Module

Add the module to the registry in `lib/metrics_agent/modules/module_supervisor.ex`:

```elixir
# Module registry: maps configuration keys to their module implementations
@module_registry %{
  demo: MetricsAgent.Modules.Demo.Demo,
  tasmota: MetricsAgent.Modules.Tasmota.Tasmota,
  prometheus: MetricsAgent.Modules.Prometheus.Prometheus  # <-- Add this line
}
```

## That's It!

The generic `get_enabled_modules/0` function will automatically:

1. ✅ Check if `:prometheus` configuration exists
2. ✅ Check if `enabled: true` is set
3. ✅ Add the module to the supervisor's children list
4. ✅ Log "Prometheus module is enabled"
5. ✅ Start the module if enabled, or log "Prometheus module is disabled" if not

## Benefits of the Generic Approach

- **No hardcoded module names** in the supervisor logic
- **Easy to add new modules** - just 3 steps above
- **Consistent behavior** - all modules follow the same enable/disable pattern
- **Maintainable** - changes to the supervisor logic apply to all modules
- **Scalable** - can easily support dozens of modules without code changes

## Usage Examples

### TOML Configuration

```toml
# Enable the new module
[modules.prometheus]
enabled = true
interval = 30000
endpoint = "http://localhost:9090/metrics"

# Disable the module
[modules.prometheus]
enabled = false
interval = 30000
endpoint = "http://localhost:9090/metrics"

# Device-specific configuration
[modules.prometheus.devices."production-server"]
enabled = true
endpoint = "http://prod-server:9090/metrics"
interval = 60000
```

The module will be automatically started or skipped based on the `enabled` setting!

### Device-Specific Configuration

You can also get device-specific configuration in your module:

```elixir
# Get global configuration
config = MetricsAgent.ConfigLoader.get_module_config(:prometheus)

# Get device-specific configuration (with overrides applied)
device_config = MetricsAgent.ConfigLoader.get_module_config(:prometheus, "device1")
```
