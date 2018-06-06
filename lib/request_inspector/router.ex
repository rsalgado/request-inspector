defmodule RequestInspector.Router do
  alias RequestInspector.RequestsAgent
  alias RequestInspector.StreamAgent
  require Logger
  require IEx

  use Plug.Router
  use Plug.Debugger   # This should be only used for development.

  # Use the names of the modules as the names of the agents
  @requests_agent   RequestsAgent
  @stream_agent     StreamAgent
  

  plug(
    Plug.Static,
    at: "/",
    from: :request_inspector
  )

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json, RequestInspector.Parsers.Text],
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
      @requests_agent
      |> RequestsAgent.get_requests()
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
      |> parse_request()                                # Parse request into a map
      |> RequestsAgent.store_request(@requests_agent)   # Store the request
      |> Poison.encode!(pretty: true)                   # Create a JSON string with the request

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
    StreamAgent.set_connection_pid(self(), @stream_agent)

    # Send initial response to open the stream and then, start the loop streaming events to browser
    # Return the connection when the loop is over: stream_loop returns the connection.
    conn
      |> put_resp_header("content-type", "text/event-stream")
      |> send_chunked(200)
      |> stream_loop()
  end

  # Default endpoint (matches anything else)
  match _ do
    Logger.warn("#{conn.method} request to #{conn.request_path}")
    send_resp(conn, 404, "Oops! Invalid request. Try again.")
  end


  # Private functions

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

  # Send message to process (PID) to trigger notification
  defp notify_update() do
    conn_pid = StreamAgent.get_connection_pid(@stream_agent)
    if conn_pid do 
      send(conn_pid, :notify)
    end
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
            # Chunk couldn't be sent. Break the loop. Return the connection.
            Logger.warn("Unable to send chunk. Stream is getting closed.")
            conn
        end
      
      :close_stream ->
        # Close the stream (and break the loop). Return the connection
        # This can be used to close connection from iex or another place
        Logger.warn("Stream closed")
        conn
    end
  end

end
