defmodule RequestInspector do
  use Application
  require Logger

  @registry :endpoint_servers
  @dynamic_supervisor RequestInspector.DynamicSupervisor

  def start(_type, _args) do
    # Use the modules names as agents' names. 
    # Also used in `RequestInspector.Router` attributes
    children = [
      Registry.child_spec(
        keys: :unique,
        name: @registry),
      {DynamicSupervisor,
        strategy: :one_for_one,
        name: @dynamic_supervisor},
      {Plug.Adapters.Cowboy2,
        scheme: :http,
        plug: RequestInspector.Router,
        options: [
          port: 5000,
          # Using :infinity because Cowboy2 by default waits 60s before closing the conn.
          # TODO: Find a better way to deal with SSE in Cowboy2 using Plug to avoid this workaround.
          protocol_options: [idle_timeout: :infinity]]}
    ]

    Logger.info("Starting server on port 5000")
    Supervisor.start_link(children, strategy: :one_for_one)
  end

end
