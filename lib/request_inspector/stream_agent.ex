defmodule StreamAgent do
  require Logger

  use Agent

  def start_link(_) do
    Logger.info("Starting StreamsAgent")
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end

  def set_connection_pid(new_pid) do
    Agent.update(__MODULE__, fn _ -> new_pid end)
    Logger.info("StreamsAgent updated")
  end

  def get_connection_pid() do
    Agent.get(__MODULE__, & &1)
  end
end
