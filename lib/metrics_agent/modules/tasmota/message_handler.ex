defmodule MetricsAgent.Modules.Tasmota.MessageHandler do
  @moduledoc """
  Tortoise handler for Tasmota MQTT messages.
  """

  use Tortoise.Handler
  require Logger

  @impl true
  def init(initial_args) do
    client_id = Keyword.get(initial_args, :client_id)
    {:ok, %{client_id: client_id}}
  end

  @impl true
  def handle_message(["tasmota", "discovery", device_mac, "config"], payload, state) do
    Logger.debug("Received device discovery message")

    case Jason.decode(payload) do
      {:ok, device_info} ->
        Logger.info(
          "Discovered Tasmota device: #{device_mac} (#{device_info["dn"]} on #{device_info["ip"]})"
        )

        # Subscribe to sensor data for this device if topic is present
        if device_info["t"] do
          sensor_topic = "tele/#{device_info["t"]}/SENSOR"

          {:ok, ref} = Tortoise.Connection.subscribe(state.client_id, [{sensor_topic, 0}])
          Logger.debug("Subscribed to sensor topic: #{sensor_topic} with ref: #{inspect(ref)}")
        end

        {:ok, state}

      {:error, reason} ->
        Logger.error("Failed to parse device discovery message: #{reason}")
        {:ok, state}
    end
  end

  @impl true
  def handle_message(["tele", device_name, "SENSOR"], payload, state) do
    Logger.debug("Received sensor data from device: #{device_name}")
    {:ok, state}
  end

  # Fallback for any other topics
  def handle_message(topic, payload, state) do
    Logger.debug("Received message on unexpected topic: #{Enum.join(topic, "/")}")
    {:ok, state}
  end

  @impl true
  def connection(status, state) do
    Logger.info("MQTT connection status: #{status}")
    {:ok, state}
  end

  @impl true
  def subscription(:up, topic_filter, state) do
    Logger.info("Successfully subscribed to topic: #{topic_filter}")
    {:ok, state}
  end

  def subscription(:down, topic_filter, state) do
    Logger.info("Unsubscribed from topic: #{topic_filter}")
    {:ok, state}
  end

  def subscription({:warn, [requested: req, accepted: qos]}, topic_filter, state) do
    Logger.warning(
      "Subscribed to #{topic_filter}; requested QoS #{req} but got accepted with QoS #{qos}"
    )

    {:ok, state}
  end

  def subscription({:error, reason}, topic_filter, state) do
    Logger.error("Error subscribing to #{topic_filter}; #{inspect(reason)}")
    {:ok, state}
  end

  def subscription(status, topic_filter, state) do
    Logger.warning(
      "Unexpected subscription status: #{inspect(status)} for topic: #{topic_filter}"
    )

    {:ok, state}
  end
end
