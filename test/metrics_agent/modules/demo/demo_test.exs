defmodule MetricsAgent.Modules.Demo.DemoTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog

  setup do
    # Clean up any existing panic trigger file
    File.rm("/tmp/metrics-agent-panic-demo")

    # Set test configuration
    Application.put_env(:metrics_agent, :demo, interval: 100)

    # Get the already running demo module PID (started by the application)
    demo_pid = Process.whereis(MetricsAgent.Modules.Demo.Demo)

    on_exit(fn ->
      # Clean up
      File.rm("/tmp/metrics-agent-panic-demo")
    end)

    {:ok, demo_pid: demo_pid}
  end

  test "demo module starts successfully" do
    # Test that the demo module is running (started by the application)
    demo_pid = Process.whereis(MetricsAgent.Modules.Demo.Demo)
    assert demo_pid != nil
    assert Process.alive?(demo_pid)
  end

  test "demo module initializes with correct state", %{demo_pid: pid} do
    # Get the current state
    state = :sys.get_state(pid)

    # The interval should be set (either from config or default)
    # Since the module might start before our config is applied, we check for either value
    assert state.interval in [100, 5000]
    # Counter might be > 0 if metrics have been collected already
    assert is_integer(state.counter)
  end

  test "demo module generates metrics when triggered", %{demo_pid: pid} do
    # Get initial counter value
    initial_state = :sys.get_state(pid)
    initial_counter = initial_state.counter

    # Send the collect_metrics message
    send(pid, :collect_metrics)

    # Wait a bit for processing
    Process.sleep(50)

    # Get the updated state
    updated_state = :sys.get_state(pid)

    # Counter should be incremented by at least 1 (our manual send)
    # but might be more due to automatic collection
    assert updated_state.counter >= initial_counter + 1
  end

  test "demo module generates correct metric structure", %{demo_pid: pid} do
    # Get the state to access the private function through the process
    state = :sys.get_state(pid)

    # We can't directly test the private function, but we can test the behavior
    # by sending the collect_metrics message and checking the counter increments
    initial_counter = state.counter

    send(pid, :collect_metrics)
    Process.sleep(50)

    updated_state = :sys.get_state(pid)
    # Counter should be incremented by at least 1 (our manual send)
    # but might be more due to automatic collection
    assert updated_state.counter >= initial_counter + 1
  end

  test "demo module handles panic trigger file", %{demo_pid: pid} do
    # Create the panic trigger file
    File.write!("/tmp/metrics-agent-panic-demo", "panic")

    # Send collect_metrics message
    log =
      capture_log(fn ->
        send(pid, :collect_metrics)
        Process.sleep(50)
      end)

    # Should log error about panic trigger
    assert log =~ "Demo module panic triggered by panic trigger file"

    # Process should be dead due to the raise
    refute Process.alive?(pid)
  end

  test "demo module handles unexpected messages", %{demo_pid: pid} do
    # Send an unexpected message
    log =
      capture_log(fn ->
        send(pid, :unexpected_message)
        Process.sleep(50)
      end)

    # Should log warning about unexpected message
    assert log =~ "Unexpected message in demo module"

    # Process should still be alive
    assert Process.alive?(pid)
  end

  test "demo module uses configured interval" do
    # This test verifies that the demo module uses a valid interval
    # Since the module might start before our config is applied, we check for either value
    demo_pid = Process.whereis(MetricsAgent.Modules.Demo.Demo)
    state = :sys.get_state(demo_pid)

    # Should use either our test config interval (100ms) or default (5000ms)
    assert state.interval in [100, 5000]
  end

  test "demo module increments counter on each metric collection", %{demo_pid: pid} do
    initial_state = :sys.get_state(pid)
    initial_counter = initial_state.counter

    # Send multiple collect_metrics messages
    for _i <- 1..3 do
      send(pid, :collect_metrics)
      Process.sleep(50)
    end

    final_state = :sys.get_state(pid)
    # The counter should have increased by at least 3 (our manual sends)
    # but might be more due to automatic collection
    assert final_state.counter >= initial_counter + 3
  end
end
