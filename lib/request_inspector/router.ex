defmodule RequestInspector.Router do
  @moduledoc """
  Plug Router for handling all the HTTP requests: serving the static files (like the index.html page),
  handling the HTTP requests made to the endpoint, getting the list of requests made, and handling SSE.

  ## Routes (Endpoints)

      GET  /:key              Serves priv/static/index.html. Equivalent to GET /index.html
      GET  /:key/requests     See (inspect) all the requests you have made to /endpoint
      *    /:key/endpoint     Endpoint (send your requests here)
      GET  /:key/sse          SSE endpoint
  """

  alias RequestInspector.{RequestsAgent, StreamAgent, EndpointServer}
  require Logger

  use Plug.Router
  use Plug.Debugger   # This should be only used for development.

  @registry :endpoint_servers
  @dynamic_supervisor RequestInspector.DynamicSupervisor


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

  post "/keys" do
    conn = put_resp_header(conn, "content-type", "application/json")

    # Generate a key and build the naming tuple with it 
    # Use our custom child spec that receives the opts instead of args for start_link
    new_key = EndpointServer.generate_key()
    gs_name = {:via, Registry, {@registry, new_key}}
    child_spec = EndpointServer.custom_child_spec(name: gs_name)

    case DynamicSupervisor.start_child(@dynamic_supervisor, child_spec) do
      {:ok, _} ->
        json_response = Poison.encode!(%{key: new_key}, pretty: true)
        send_resp(conn, 201, json_response)
      
      _ ->
        json_response = Poison.encode!(%{error: "Couldn't create GenServer"}, pretty: true)
        send_resp(conn, 400, json_response)
    end
  end

  # See (inspect) all the requests you have made to /endpoint
  get "/:key/requests" do
    conn = put_resp_header(conn, "content-type", "application/json")
    case Registry.lookup(@registry, key) do
      [{gen_server, nil}] ->
        {:ok, requests_agent} = EndpointServer.get_requests_agent(gen_server)
        json_response =
          requests_agent
          |> RequestsAgent.get_requests()
          |> Poison.encode!(pretty: true)

        send_resp(conn, 200, json_response)
      
      _ ->
        json_response = Poison.encode!(%{error: "Key not found"}, pretty: true)
        send_resp(conn, 400, json_response)
    end
  end

  # Endpoint (send your requests here)
  match "/:key/endpoint" do
    conn = put_resp_header(conn, "content-type", "application/json")
    case Registry.lookup(@registry, key) do
      [{gen_server, nil}] ->
        {:ok, requests_agent} = EndpointServer.get_requests_agent(gen_server)
        {:ok, stream_agent} = EndpointServer.get_stream_agent(gen_server)

        # Store and encode request
        json_response =
          conn
          |> parse_request()                                # Parse request into a map
          |> RequestsAgent.store_request(requests_agent)    # Store the request
          |> Poison.encode!(pretty: true)                   # Create a JSON string with the request
        # Notify update to browser
        notify_update(stream_agent)
        # Respond with request info as a JSON
        send_resp(conn, 200, json_response)

      _ ->
        json_response = Poison.encode!(%{error: "Key not found"}, pretty: true)
        send_resp(conn, 400, json_response)
    end
  end

  # SSE endpoint
  get "/:key/sse" do
    [{gen_server, nil}] = Registry.lookup(@registry, key)
    {:ok, stream_agent} = EndpointServer.get_stream_agent(gen_server)
    # Store current connection's process ID
    StreamAgent.set_connection_pid(self(), stream_agent)

    # Send initial response to open the stream and then, start the loop streaming events to browser
    # Return the connection when the loop is over: stream_loop returns the connection.
    conn
      |> put_resp_header("content-type", "text/event-stream")
      |> send_chunked(200)
      |> stream_loop()
  end

  get "/:key" do
    case Registry.lookup(@registry, key) do
      [{_gen_server, nil}] ->
        conn
        |> put_resp_header("content-type", "text-html")
        |> send_file(200, "priv/static/index.html")
      
      _ ->
        Logger.warn("#{conn.method} request to #{conn.request_path}")
        send_resp(conn, 400, "Key not found")
    end
  end

  # Default endpoint (matches anything else)
  match _ do
    Logger.warn("#{conn.method} request to #{conn.request_path}")
    send_resp(conn, 404, "Oops! Invalid request. Try again.")
  end


  # Private functions

  # Build a map using the request info from the connection
  @spec parse_request(Plug.Conn.t) :: map
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
  defp notify_update(stream_agent) do
    conn_pid = StreamAgent.get_connection_pid(stream_agent)
    if conn_pid do 
      send(conn_pid, :notify)
    end
  end

  # Listen to internal messages to current connection's process
  @spec stream_loop(Plug.Conn.t) :: Plug.Conn.t
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
