defmodule RequestInspector.Router do
  alias RequestInspector.RequestsAgent
  require Logger
  require IEx

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

  get "/" do
    conn
    |> put_resp_header("content-type", "text-html")
    |> send_file(200, "priv/static/index.html")
  end

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
    # Store and encode request
    json_response =
      conn
      |> parse_request()
      |> RequestsAgent.store_request()  # Store the request
      |> Poison.encode!(pretty: true)   # Create a JSON string with it

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

    # Send initial response to open the stream
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

  # Listen to internal messages to current connection's process
  defp stream_events(conn) do
    receive do
      # Send an update message to browser and loop (with a tail call)
      :updated ->
        message_data = "updated"
        Plug.Conn.chunk(conn, ~s(data: #{message_data}\n\n))
        stream_events(conn) # Loop

      # Close the stream (and break the loop)
      # This is not used in the code currently, but might be useful (for example in iex)
      :close_stream ->
        Logger.warn("Stream closed")
    end
    # Return the connection
    conn
  end

  defp notify_update() do
    conn_pid = StreamAgent.get_connection_pid()
    send(conn_pid, :updated)
  end
end
