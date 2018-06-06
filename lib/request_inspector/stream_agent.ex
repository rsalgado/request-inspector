defmodule RequestInspector.StreamAgent do
  require Logger

  use Agent

  def start_link(opts) do
    Logger.info("Starting stream agent")
    Agent.start_link(fn -> nil end, opts)
  end

  def set_connection_pid(new_pid, agent) do
    Agent.update(agent, fn _ -> new_pid end)
    Logger.info("Stream agent updated")
    new_pid
  end

  def get_connection_pid(agent) do
    conn_pid = Agent.get(agent, & &1)
    
    cond do
      conn_pid == nil ->
        nil
      Process.alive?(conn_pid) ->
        conn_pid
      true ->
        # Process is dead. Update the state to nil and return it (nil)
        set_connection_pid(nil, agent)
    end
  end
end
