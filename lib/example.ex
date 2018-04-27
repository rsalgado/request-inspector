defmodule Example do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Example.Router, [], port: 5000),
      Example.RequestsAgent.child_spec([])
    ]

    Logger.info("Starting server on port 5000")
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
