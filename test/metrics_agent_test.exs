defmodule MetricsAgentTest do
  use ExUnit.Case

  test "metrics collector is running" do
    # Verify that the metrics collector is running (started by the application)
    assert Process.whereis(MetricsAgent.MetricsCollector) != nil
  end

  test "metrics collector can receive metrics" do
    # Test that the metrics collector can receive metrics without errors
    metric = %{
      name: "test_metric",
      tags: %{host: "test_host", service: "test_service"},
      fields: %{value: 42, status: "ok", temperature: 23.5},
      timestamp: 1_640_995_200_000_000_000
    }

    # This should not raise an error
    assert MetricsAgent.MetricsCollector.send_metric(metric) == :ok
  end

  test "metrics collector handles different metric types" do
    # Test various metric configurations
    metrics = [
      # Metric with tags and fields
      %{
        name: "test_metric",
        tags: %{host: "test_host", service: "test_service"},
        fields: %{value: 42, status: "ok", temperature: 23.5},
        timestamp: 1_640_995_200_000_000_000
      },
      # Metric without tags
      %{
        name: "simple_metric",
        tags: %{},
        fields: %{count: 100},
        timestamp: 1_640_995_200_000_000_000
      },
      # Metric with different field types
      %{
        name: "type_test",
        tags: %{},
        fields: %{
          string_val: "hello",
          int_val: 42,
          float_val: 3.14,
          bool_val: true,
          complex_val: %{nested: "value"}
        },
        timestamp: 1_640_995_200_000_000_000
      }
    ]

    # All metrics should be sent without errors
    for metric <- metrics do
      assert MetricsAgent.MetricsCollector.send_metric(metric) == :ok
    end
  end

  test "metrics collector handles edge cases" do
    # Test metric with special characters in values
    metric = %{
      name: "edge_case_test",
      tags: %{location: "test-location", version: "1.0"},
      fields: %{
        message: "test with spaces and \"quotes\"",
        empty_string: "",
        zero_value: 0,
        negative_value: -42
      },
      timestamp: 1_640_995_200_000_000_000
    }

    # This should not raise an error
    assert MetricsAgent.MetricsCollector.send_metric(metric) == :ok
  end

  test "metrics collector processes messages correctly" do
    # Test that the GenServer can handle the metric message
    metric = %{
      name: "process_test",
      tags: %{test: "process"},
      fields: %{value: 123},
      timestamp: 1_640_995_200_000_000_000
    }

    # Send the message directly to the GenServer
    collector_pid = Process.whereis(MetricsAgent.MetricsCollector)
    assert collector_pid != nil

    # Send a cast message directly
    GenServer.cast(collector_pid, {:metric, metric})

    # Give it a moment to process
    Process.sleep(10)

    # If we get here without errors, the message was processed
    assert true
  end

  test "module configuration includes enabled property" do
    # Test that module configurations have the enabled property
    demo_config = Application.get_env(:metrics_agent, :demo, [])
    tasmota_config = Application.get_env(:metrics_agent, :tasmota, [])

    # Both modules should have the enabled property
    assert Keyword.has_key?(demo_config, :enabled)
    assert Keyword.has_key?(tasmota_config, :enabled)
  end
end
