defmodule Example.RequestsAgent do
  require Logger

  use Agent

  def start_link(_) do
    Logger.info("Starting RequestsAgent")
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def store_request(request) do
    Agent.update(__MODULE__, fn requests -> [request | requests] end)

    Logger.info("RequestsAgent length: #{Agent.get(__MODULE__, &length(&1))} items")
    request
  end

  def get_requests() do
    Agent.get(__MODULE__, & &1)
  end
end
