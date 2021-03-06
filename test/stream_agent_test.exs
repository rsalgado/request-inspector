defmodule RequestInspector.StreamAgentTest do
  alias RequestInspector.StreamAgent
  use ExUnit.Case, async: true

  setup do
    {:ok, agent} = StreamAgent.start_link []
    %{agent: agent}
  end

  test "Has nil as initial value", %{agent: agent} do
    assert Agent.get(agent, & &1) == nil
  end

  test "Sets connection PID", %{agent: agent} do
    temp_proc = spawn(fn  ->  :timer.sleep(50) end)
    StreamAgent.set_connection_pid(temp_proc, agent)

    assert Agent.get(agent, & &1) == temp_proc
  end

  test "Allows getting PID", %{agent: agent} do
    temp_proc = spawn(fn  ->  :timer.sleep(50) end)
    StreamAgent.set_connection_pid(temp_proc, agent)

    assert StreamAgent.get_connection_pid(agent) == temp_proc
    # Wait enough to make sure the spawned process died
    :timer.sleep(75)
    assert StreamAgent.get_connection_pid(agent) == nil
  end
end