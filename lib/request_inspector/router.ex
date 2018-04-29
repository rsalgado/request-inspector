defmodule RequestInspector.Router do
  alias RequestInspector.RequestsAgent
  require Logger

  use Plug.Router

  plug(
    Plug.Static,
    at: "/",
    from: :request_inspector
  )

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    json_decoder: Poison
  )

  plug(:match)
  plug(:dispatch)

  ## Endpoints

  # See (inspect) all the requests you have made to /endpoint
  get "/requests" do
    json_response =
      RequestsAgent.get_requests()
      |> Poison.encode!(pretty: true)

    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(200, json_response)
  end

  # Endpoint (send your requests here)
  match "/endpoint" do
    # Create the response
    json_response =
      conn
      |> parse_request()
      |> RequestsAgent.store_request()
      |> Poison.encode!(pretty: true)

    # Notify update to browser
    notify_update()

    # Respond with request info as a JSON
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(200, json_response)
  end

  # SSE endpoint
  get "/sse" do
    # Store current connection's process ID
    StreamAgent.set_connection_pid(self())

    # Send initial response
    conn =
      conn
      |> put_resp_header("content-type", "text/event-stream")
      |> send_chunked(200)

    # Start streaming events to browser (returns the conn when done)
    stream_events(conn)
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

  defp stream_events(conn) do
    # Listen to internal messages to this process 
    receive do
      # Send a update message to browser and loop (with tail-call)
      :updated ->
        Plug.Conn.chunk(conn, ~s(data: updated\n\n))
        stream_events(conn)

      # Give back the conn (and break the loop)
      :close_stream ->
        conn
    end
  end

  defp notify_update() do
    conn_pid = StreamAgent.get_connection_pid()
    send(conn_pid, :updated)
  end
end
