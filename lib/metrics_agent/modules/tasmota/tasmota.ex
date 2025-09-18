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
    {:ok, pid} =
      :emqtt.start_link([
        # oder 'localhost'
        {:host, config[:mqtt_host]},
        {:port, config[:mqtt_port]},
        {:clientid, client_id},
        {:username, ""},
        {:password, ""},
        {:clean_start, true},
        {:keepalive, 60}
      ])

    # Connect to MQTT broker
    {:ok, _props} = :emqtt.connect(pid)

    # Subscribe to discovery topic
    :emqtt.subscribe(pid, {config[:discovery_topic], 0})

    Logger.info("Tasmota module started with MQTT client: #{client_id}")
    {:ok, %{pid: pid}}
  end

  @impl true
  def handle_info({:publish, publish}, state) do
    MetricsAgent.Modules.Tasmota.MessageHandler.handle_mqtt_message(publish, state.pid)
    {:noreply, state}
  end

  # Private functions
  defp generate_client_id do
    {:ok, hostname} = :inet.gethostname()
    hostname_string = List.to_string(hostname)
    "#{hostname_string}-tasmota-#{:rand.uniform(10000)}"
  end
end
