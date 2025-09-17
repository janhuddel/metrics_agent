defmodule MetricsAgent.Modules.Tasmota.Tasmota do
  @moduledoc """
  Tasmota module for collecting metrics from Tasmota devices.
  """

  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting Tasmota module")

    config = Application.get_env(:metrics_agent, :tasmota)

    # Generate client ID if not provided
    client_id = config[:client_id] || generate_client_id()

    # Start MQTT client
    {:ok, client} =
      Tortoise.Connection.start_link(
        client_id: client_id,
        server: {Tortoise.Transport.Tcp, host: config[:mqtt_host], port: config[:mqtt_port]},
        user_name: config[:username] || "",
        password: config[:password] || "",
        keep_alive: config[:keep_alive] || 60,
        will: nil,
        subscriptions: [
          {config[:discovery_topic], 1}
        ],
        handler: {MetricsAgent.Modules.Tasmota.MessageHandler, [client_id: client_id]}
      )

    Logger.info("Tasmota module started with MQTT client: #{client_id}")
    {:ok, %{client: client}}
  end

  # Private functions
  defp generate_client_id do
    hostname =
      case :inet.gethostname() do
        {:ok, hostname} -> List.to_string(hostname)
        {:error, _} -> "unknown"
      end

    "#{hostname}-tasmota-#{:rand.uniform(10000)}"
  end
end
