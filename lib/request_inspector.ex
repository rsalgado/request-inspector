defmodule RequestInspector do
  use Application

  require Logger

  @registry :endpoint_servers
  @dynamic_supervisor RequestInspector.DynamicSupervisor

  def start(_type, _args) do
    # Use the modules names as agents' names. 
    # Also used in `RequestInspector.Router` attributes
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, RequestInspector.Router, [], port: 5000),
      Registry.child_spec(keys: :unique, name: @registry),
      {DynamicSupervisor, strategy: :one_for_one, name: @dynamic_supervisor}
    ]

    Logger.info("Starting server on port 5000")
    Supervisor.start_link(children, strategy: :one_for_one)
  end


  @doc """
  Helper function to get the keys of all the `EndpointServer`s being supervised
  """
  @spec gen_servers_keys() :: [String.t]
  def gen_servers_keys() do
    DynamicSupervisor.which_children(@dynamic_supervisor)
    |> Enum.map(fn {_, pid, _, _} ->  pid end)
    |> Enum.map(fn(pid) ->  Registry.keys(@registry, pid) end)
    |> Enum.reduce([], fn(x, acc) ->  acc ++ x end)
  end
end
