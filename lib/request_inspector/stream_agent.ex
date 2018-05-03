defmodule RequestInspector.StreamAgent do
  require Logger

  use Agent

  def start_link(_) do
    Logger.info("Starting stream agent")
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end

  def set_connection_pid(new_pid) do
    Agent.update(__MODULE__, fn _ -> new_pid end)
    Logger.info("Stream agent updated")
    new_pid
  end

  def get_connection_pid() do
    conn_pid = Agent.get(__MODULE__, & &1)
    
    cond do
      conn_pid == nil ->
        nil
      Process.alive?(conn_pid) ->
        conn_pid
      true ->
        # Process is dead. Update the state to nil and return it (nil)
        set_connection_pid(nil)
    end
  end
end
