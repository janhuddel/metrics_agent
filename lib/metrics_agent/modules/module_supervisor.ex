defmodule MetricsAgent.Modules.ModuleSupervisor do
  @moduledoc """
  Supervisor for all metric collection modules.
  """

  use Supervisor
  require Logger

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting module supervisor")

    # Create children for enabled modules
    children = [{MetricsAgent.Modules.Tasmota.Tasmota, []}]

    # One-for-one strategy: if one module crashes, only restart that one
    Supervisor.init(children, strategy: :one_for_one)
  end
end
