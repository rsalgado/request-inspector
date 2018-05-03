defmodule RequestInspector.Router do
  alias RequestInspector.RequestsAgent
  alias RequestInspector.StreamAgent
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
    parsers: [:urlencoded, :multipart, :json, RequestsInspector.Parsers.Text],
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

    # Start streaming events to browser
    stream_loop(conn)

    # Return the connection
    conn
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
  defp stream_loop(conn) do
    # Text to be sent as SSE chunk
    message_data = "updated"
    sse_message = ~s(data: #{message_data}\n\n)

    receive do
      :notify ->
        # Try to send a SSE message to notify browser that state was updated
        # If chunk was sent succesfully, loop (with a recursive tail call)
        # If chunk couldn't be sent, send process message to close stream
        case Plug.Conn.chunk(conn, sse_message) do
          {:ok, conn} ->  
            stream_loop(conn)

          _ ->
            Logger.warn("Unable to send chunk. Stream is getting closed.")
            send(self(), :close_stream)   # Send :close_stream message to itself
        end
      
      :close_stream ->
        # Close the stream (and break the loop)
        # This can also be used to close connection from iex or another place
        Logger.warn("Stream closed")
    end
  end

  # Send message to process (PID) to trigger notification
  defp notify_update() do
    conn_pid = StreamAgent.get_connection_pid()
    if conn_pid do 
      send(conn_pid, :notify)
    end
  end
end
