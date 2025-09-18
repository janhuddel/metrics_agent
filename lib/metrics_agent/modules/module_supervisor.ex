defmodule MetricsAgent.Modules.ModuleSupervisor do
  @moduledoc """
  Supervisor for all metric collection modules.
  """

  use Supervisor
  require Logger

  # Module registry: maps configuration keys to their module implementations
  @module_registry %{
    demo: MetricsAgent.Modules.Demo.Demo,
    tasmota: MetricsAgent.Modules.Tasmota.Tasmota
  }

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting module supervisor")

    # Create children for enabled modules
    children = get_enabled_modules()

    Logger.info("Starting #{length(children)} enabled modules")

    # One-for-one strategy: if one module crashes, only restart that one
    Supervisor.init(children, strategy: :one_for_one)
  end

  # Private function to get enabled modules from configuration
  defp get_enabled_modules do
    @module_registry
    |> Enum.reduce([], fn {config_key, module_impl}, acc ->
      config = MetricsAgent.ConfigLoader.get_module_config(config_key)

      if config[:enabled] do
        Logger.info("#{String.capitalize(to_string(config_key))} module is enabled")
        [{module_impl, []} | acc]
      else
        Logger.info("#{String.capitalize(to_string(config_key))} module is disabled")
        acc
      end
    end)
    |> Enum.reverse()
  end
end
