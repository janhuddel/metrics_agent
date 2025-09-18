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

  @impl true
  def init(_opts) do
    Logger.info("Starting Prometheus module")
    
    config = Application.get_env(:metrics_agent, :prometheus)
    interval = config[:interval] || 30000
    endpoint = config[:endpoint] || "http://localhost:9090/metrics"
    
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

Add configuration to `config/config.exs`:

```elixir
# Prometheus module configuration
config :metrics_agent, :prometheus,
  enabled: true,
  interval: 30000,
  endpoint: "http://localhost:9090/metrics"
```

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

```elixir
# Enable the new module
config :metrics_agent, :prometheus,
  enabled: true,
  interval: 30000,
  endpoint: "http://localhost:9090/metrics"

# Disable the module
config :metrics_agent, :prometheus,
  enabled: false,
  interval: 30000,
  endpoint: "http://localhost:9090/metrics"
```

The module will be automatically started or skipped based on the `enabled` setting!
