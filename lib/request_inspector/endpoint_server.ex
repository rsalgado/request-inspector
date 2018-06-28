defmodule RequestInspector.EndpointServer do
  require Logger
  use GenServer

  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def get_requests_agent(gen_server) do
    GenServer.call(gen_server, :get_req_agent)
  end

  def get_stream_agent(gen_server) do
    GenServer.call(gen_server, :get_stream_agent)
  end


  def init(_args) do
    Logger.info("Starting EndpointServer #{inspect self()}")
    {:ok, req_agent} = RequestInspector.RequestsAgent.start_link []
    {:ok, stream_agent} = RequestInspector.StreamAgent.start_link []

    state = {req_agent, stream_agent}
    {:ok, state}
  end

  def terminate(_reason, {req_agent, stream_agent}) do
    Agent.stop(req_agent)
    Agent.stop(stream_agent)
  end

  def handle_call(:get_req_agent, _from,  {req_agent, _stream_agent} = state) do
    response = {:ok, req_agent}
    {:reply, response, state}
  end

  def handle_call(:get_stream_agent, _from, {_req_agent, stream_agent} = state) do
    response = {:ok, stream_agent}
    {:reply, response, state}
  end

  def generate_key(n \\ 8) do
    '0123456789abcdefghijklmnopqrstuvwxyz'
    |> Enum.take_random(n)
    |> List.to_string()
  end
end