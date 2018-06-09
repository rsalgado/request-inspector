defmodule RequestInspector.EndpointServer do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def get_requests_agent(gen_server) do
    GenServer.call(gen_server, :get_req_agent)
  end

  def get_stream_agent(gen_server) do
    GenServer.call(gen_server, :get_stream_agent)
  end



  def init(args) do
    {:ok, req_agent} = RequestInspector.RequestsAgent.start_link []
    {:ok, stream_agent} = RequestInspector.StreamAgent.start_link []

    state = {req_agent, stream_agent}
    {:ok, state}
  end

  def handle_call(:get_req_agent, _from,  {req_agent, stream_agent} = state) do
    response = {:ok, req_agent}
    {:reply, response, state}
  end

  def handle_call(:get_stream_agent, _from, {req_agent, stream_agent} = state) do
    response = {:ok, stream_agent}
    {:reply, response, state}
  end
end