defmodule RequestInspector.BucketServer do
  require Logger
  use GenServer

  @registry :endpoint_servers
  @dynamic_supervisor RequestInspector.DynamicSupervisor

  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  @spec get_requests_agent(pid) :: pid
  def get_requests_agent(gen_server) do
    GenServer.call(gen_server, :get_req_agent)
  end

  @spec get_stream_agent(pid) :: pid
  def get_stream_agent(gen_server) do
    GenServer.call(gen_server, :get_stream_agent)
  end

  @doc """
  Helper function to generate a random string of `n` chars (8 by default).
  Possible characters are digits and lowercase letters.
  """
  @spec generate_key(integer) :: String.t
  def generate_key(n \\ 8) do
    '0123456789abcdefghijklmnopqrstuvwxyz'
    |> Enum.take_random(n)
    |> List.to_string()
  end

  @doc """
  Helper function to get the keys of all the `BucketServer`s being supervised
  """
  @spec gen_servers_keys() :: [String.t]
  def gen_servers_keys() do
    DynamicSupervisor.which_children(@dynamic_supervisor)
    |> Enum.map(fn {_, pid, _, _} ->  pid end)
    |> Enum.map(fn(pid) ->  Registry.keys(@registry, pid) end)
    |> Enum.reduce([], fn(x, acc) ->  acc ++ x end)
  end  

  def custom_child_spec(opts) do
    %{
      id: __MODULE__,
      restart: :transient,
      start: {__MODULE__, :start_link, [[], opts]}
    }
  end


  def init(_args) do
    Logger.info("Starting BucketServer #{inspect self()}")
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
end
