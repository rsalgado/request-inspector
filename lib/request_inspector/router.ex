defmodule RequestInspector.Router do
  alias RequestInspector.RequestsAgent
  require IEx
  require Logger

  use Plug.Router

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    json_decoder: Poison
  )

  plug(:match)
  plug(:dispatch)

  ## Endpoints

  # See (inspect) all the requests you have made to /endpoint
  get "/inspect" do
    json_response =
      RequestsAgent.get_requests()
      |> Poison.encode!(pretty: true)

    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(200, json_response)
  end

  # Endpoint (send your requests here)
  match "/endpoint" do
    json_response =
      conn
      |> parse_request()
      |> RequestsAgent.store_request()
      |> Poison.encode!(pretty: true)

    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(200, json_response)
  end

  # Default endpoint (matches anything else)
  match _ do
    Logger.warn("#{conn.method} request to #{conn.request_path}")
    send_resp(conn, 404, "Oops! Invalid request. Try again.")
  end

  # Build a map using the request info from the connection
  defp parse_request(connection) do
    %{
      method: connection.method,
      path: connection.request_path,
      queryParams: connection.query_params,
      body: connection.body_params,
      headers: Map.new(connection.req_headers, & &1)
    }
  end
end
