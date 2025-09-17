defmodule MetricsAgent.Application do
  @moduledoc """
  Main application module that starts the supervisor tree.
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting Metrics Agent application")

    children = [
      # Metrics collector - handles metric serialization and output
      {MetricsAgent.MetricsCollector, []},

      # Module supervisor - manages all metric collection modules
      {MetricsAgent.Modules.ModuleSupervisor, []}
    ]

    opts = [strategy: :one_for_one, name: MetricsAgent.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("Metrics Agent started successfully")
        {:ok, pid}

      {:error, reason} ->
        Logger.error("Failed to start Metrics Agent: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl true
  def stop(_state) do
    Logger.info("Stopping Metrics Agent application")
    :ok
  end
end
