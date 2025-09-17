defmodule MetricsAgentTest do
  use ExUnit.Case

  test "application can start" do
    # Test that the application can start successfully
    assert {:ok, _} = Application.ensure_all_started(:metrics_agent)

    # Verify that the main supervisor is running
    assert Process.whereis(MetricsAgent.Supervisor) != nil

    # Verify that the metrics collector is running
    assert Process.whereis(MetricsAgent.MetricsCollector) != nil

    # Verify that the module supervisor is running
    assert Process.whereis(MetricsAgent.Modules.ModuleSupervisor) != nil
  end
end
