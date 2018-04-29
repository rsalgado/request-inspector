defmodule RequestInspector do
  use Application
  
  alias RequestInspector.RequestsAgent
  require Logger

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, RequestInspector.Router, [], port: 5000),
      RequestsAgent.child_spec([]),
      StreamAgent.child_spec([]),
    ]

    Logger.info("Starting server on port 5000")
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
