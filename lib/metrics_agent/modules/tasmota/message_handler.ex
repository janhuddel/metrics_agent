defmodule MetricsAgent.Modules.Tasmota.MessageHandler do
  @moduledoc """
  Handles MQTT messages for Tasmota devices including discovery and sensor data.
  """

  require Logger

  @doc """
  Handles MQTT publish messages and routes them to appropriate handlers.
  """
  def handle_mqtt_message(%{topic: topic, payload: payload}, mqtt_pid) do
    topic_parts = String.split(topic, "/")

    case topic_parts do
      ["tasmota", "discovery", device_mac, "config"] ->
        handle_discovery_message(device_mac, payload, mqtt_pid)

      ["tele", device_name, "SENSOR"] ->
        handle_sensor_message(device_name, payload)

      _ ->
        Logger.debug("Received message on unexpected topic: #{topic}")
        :ok
    end
  end

  @doc """
  Handles device discovery messages and subscribes to sensor topics.
  """
  def handle_discovery_message(device_mac, payload, mqtt_pid) do
    Logger.debug("Received device discovery message for MAC: #{device_mac}")

    case Jason.decode(payload) do
      {:ok, device_info} ->
        Logger.info(
          "Discovered Tasmota device: #{device_mac} (#{device_info["dn"]} on #{device_info["ip"]})"
        )

        # Subscribe to sensor data for this device if topic is present
        if device_info["t"] do
          sensor_topic = "tele/#{device_info["t"]}/SENSOR"
          :emqtt.subscribe(mqtt_pid, {sensor_topic, 0})
          Logger.debug("Subscribed to sensor topic: #{sensor_topic}")
        end

        :ok

      {:error, reason} ->
        Logger.error("Failed to parse device discovery message: #{reason}")
        :ok
    end
  end

  @doc """
  Handles sensor data messages and processes them into metrics.
  """
  def handle_sensor_message(device_name, payload) do
    Logger.debug("Received sensor data from device: #{device_name}")

    case Jason.decode(payload) do
      {:ok, sensor_data} ->
        # Process sensor data and send metrics
        process_sensor_data(device_name, sensor_data)
        :ok

      {:error, reason} ->
        Logger.error("Failed to parse sensor data from #{device_name}: #{reason}")
        :ok
    end
  end

  @doc """
  Processes sensor data and creates metrics for common sensor types.
  """
  def process_sensor_data(device_name, sensor_data) do
    timestamp = System.system_time(:nanosecond)

    # Extract common sensor data
    metrics = []

    # Add temperature if present
    metrics =
      if sensor_data["Temperature"] do
        [
          %{
            name: "tasmota_temperature",
            tags: %{device: device_name, module: "tasmota"},
            fields: %{temperature: sensor_data["Temperature"]},
            timestamp: timestamp
          }
          | metrics
        ]
      else
        metrics
      end

    # Add humidity if present
    metrics =
      if sensor_data["Humidity"] do
        [
          %{
            name: "tasmota_humidity",
            tags: %{device: device_name, module: "tasmota"},
            fields: %{humidity: sensor_data["Humidity"]},
            timestamp: timestamp
          }
          | metrics
        ]
      else
        metrics
      end

    # Add pressure if present
    metrics =
      if sensor_data["Pressure"] do
        [
          %{
            name: "tasmota_pressure",
            tags: %{device: device_name, module: "tasmota"},
            fields: %{pressure: sensor_data["Pressure"]},
            timestamp: timestamp
          }
          | metrics
        ]
      else
        metrics
      end

    # Add energy data if present (common in Tasmota power monitoring devices)
    metrics =
      if sensor_data["ENERGY"] do
        energy_data = sensor_data["ENERGY"]
        energy_metrics = []

        # Add individual energy metrics if present
        energy_metrics =
          if energy_data["Total"] do
            [
              %{
                name: "tasmota_energy_total",
                tags: %{device: device_name, module: "tasmota"},
                fields: %{total_kwh: energy_data["Total"]},
                timestamp: timestamp
              }
              | energy_metrics
            ]
          else
            energy_metrics
          end

        energy_metrics =
          if energy_data["Power"] do
            [
              %{
                name: "tasmota_energy_power",
                tags: %{device: device_name, module: "tasmota"},
                fields: %{power_w: energy_data["Power"]},
                timestamp: timestamp
              }
              | energy_metrics
            ]
          else
            energy_metrics
          end

        energy_metrics =
          if energy_data["Voltage"] do
            [
              %{
                name: "tasmota_energy_voltage",
                tags: %{device: device_name, module: "tasmota"},
                fields: %{voltage_v: energy_data["Voltage"]},
                timestamp: timestamp
              }
              | energy_metrics
            ]
          else
            energy_metrics
          end

        energy_metrics =
          if energy_data["Current"] do
            [
              %{
                name: "tasmota_energy_current",
                tags: %{device: device_name, module: "tasmota"},
                fields: %{current_a: energy_data["Current"]},
                timestamp: timestamp
              }
              | energy_metrics
            ]
          else
            energy_metrics
          end

        energy_metrics ++ metrics
      else
        metrics
      end

    # Send all metrics to the collector
    Enum.each(metrics, fn metric ->
      MetricsAgent.MetricsCollector.send_metric(metric)
    end)
  end
end
