defmodule MetricsAgent.Modules.Tasmota.Tasmota do
  @moduledoc """
  Tasmota module for collecting metrics from Tasmota devices.
  """

  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Returns the default configuration for the Tasmota module.
  """
  def default_config do
    %{
      enabled: false,
      mqtt_host: "localhost",
      mqtt_port: 1883,
      discovery_topic: "tasmota/discovery/+/config",
      client_id: ""
    }
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting Tasmota module")

    config = MetricsAgent.Utils.ConfigLoader.get_module_config(:tasmota)

    # ConfigLoader automatically applies defaults, so we can use config directly
    mqtt_host = config[:mqtt_host]
    mqtt_port = config[:mqtt_port]
    discovery_topic = config[:discovery_topic]

    # Generate client ID if not provided (empty string means auto-generate)
    client_id =
      if config[:client_id] == "" or is_nil(config[:client_id]) do
        generate_client_id()
      else
        config[:client_id]
      end

    # Start MQTT client
    {:ok, pid} =
      :emqtt.start_link([
        {:host, mqtt_host},
        {:port, mqtt_port},
        {:clientid, client_id},
        {:username, ""},
        {:password, ""},
        {:clean_start, true},
        {:keepalive, 60}
      ])

    # Connect to MQTT broker
    Logger.info("Connecting to MQTT broker: #{mqtt_host}:#{mqtt_port}")
    {:ok, _props} = :emqtt.connect(pid)

    # Subscribe to discovery topic
    :emqtt.subscribe(pid, {discovery_topic, 0})

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
