defmodule RequestInspector do
  use Application

  alias RequestInspector.RequestsAgent
  alias RequestInspector.StreamAgent
  require Logger

  def start(_type, _args) do
    children = [
      RequestsAgent.child_spec([]),
      StreamAgent.child_spec([]),
      Plug.Adapters.Cowboy.child_spec(:http, RequestInspector.Router, [], port: 5000)
    ]

    Logger.info("Starting server on port 5000")
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
