defmodule RequestInspector do
  use Application

  alias RequestInspector.RequestsAgent
  alias RequestInspector.StreamAgent
  require Logger

  def start(_type, _args) do
    # Use the modules names as agents' names. 
    # Also used in `RequestInspector.Router` attributes
    children = [
#      RequestsAgent.child_spec(name: RequestsAgent),
#      StreamAgent.child_spec(name: StreamAgent),
      Plug.Adapters.Cowboy.child_spec(:http, RequestInspector.Router, [], port: 5000),
      Registry.child_spec(keys: :unique, name: :endpoint_servers)
    ]

    Logger.info("Starting server on port 5000")
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
