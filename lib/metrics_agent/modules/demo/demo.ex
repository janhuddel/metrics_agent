defmodule MetricsAgent.Modules.Demo.Demo do
  @moduledoc """
  Demo module for testing the metrics agent.
  """

  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Returns the default configuration for the Demo module.
  """
  def default_config do
    %{
      enabled: false,
      interval: 1000,
      vendor: "demo"
    }
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting demo module")

    config = MetricsAgent.ConfigLoader.get_module_config(:demo)

    # ConfigLoader automatically applies defaults, so we can use config directly
    interval = config[:interval]
    vendor = config[:vendor]

    # Schedule first metric collection
    Process.send_after(self(), :collect_metrics, interval)

    {:ok,
     %{
       config: config,
       interval: interval,
       vendor: vendor,
       counter: 0
     }}
  end

  @impl true
  def handle_info(:collect_metrics, state) do
    # Check for panic trigger file
    if File.exists?("/tmp/metrics-agent-panic-demo") do
      Logger.error("Demo module panic triggered by panic trigger file")
      # This will cause the process to crash and be restarted by the supervisor
      raise "Demo module panic triggered by /tmp/metrics-agent-panic-demo file"
    end

    # Generate demo metrics
    metrics = generate_demo_metrics(state.counter, state.vendor)

    # Send metrics to collector
    Enum.each(metrics, &MetricsAgent.MetricsCollector.send_metric/1)

    Logger.debug("Demo module sent #{length(metrics)} metrics (counter: #{state.counter})")

    # Schedule next collection
    Process.send_after(self(), :collect_metrics, state.interval)

    {:noreply, %{state | counter: state.counter + 1}}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warning("Unexpected message in demo module: #{inspect(msg)}")
    {:noreply, state}
  end

  # Private functions

  defp generate_demo_metrics(counter, vendor) do
    timestamp = System.system_time(:nanosecond)

    [
      %{
        name: "demo_counter",
        tags: %{module: "demo", vendor: vendor},
        fields: %{value: counter},
        timestamp: timestamp
      },
      %{
        name: "demo_temperature",
        tags: %{module: "demo", sensor: "sensor1", vendor: vendor},
        fields: %{temperature: 20.0 + :rand.uniform() * 10.0},
        timestamp: timestamp
      },
      %{
        name: "demo_humidity",
        tags: %{module: "demo", sensor: "sensor1", vendor: vendor},
        fields: %{humidity: 40.0 + :rand.uniform() * 20.0},
        timestamp: timestamp
      },
      %{
        name: "demo_pressure",
        tags: %{module: "demo", sensor: "sensor1", vendor: vendor},
        fields: %{pressure: 1013.25 + :rand.uniform() * 10.0},
        timestamp: timestamp
      }
    ]
  end
end
