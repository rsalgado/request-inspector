defmodule RequestInspector.RouterTest do
  alias RequestInspector.Router
  use ExUnit.Case
  use Plug.Test

  @opts Router.init([])

  test "POST /keys creates a new GenServer with a random string as key" do
    initial_conn = 
      conn(:post, "/keys")
      |> Router.call(@opts)
    response_map = Poison.decode!(initial_conn.resp_body)
    
    assert initial_conn.status == 201
    assert Map.has_key?(response_map, "key")

    key = Map.get(response_map, "key")
    assert key in RequestInspector.gen_servers_keys()
  end

  test "GET /:key returns the index.html page" do
    random_key = create_endpoint_server()

    root_conn = 
      conn(:get, "/#{random_key}", "")
      |> Router.call(@opts)

    index_conn =
      conn(:get, "/index.html", "")
      |> Router.call(@opts)

    assert root_conn.state == :file
    assert index_conn.state == :file

    assert root_conn.status == 200
    assert index_conn.status == 200

    assert root_conn.resp_body == index_conn.resp_body
  end

  test "DELETE /:key removes endpoint GenServer with the given key" do
    random_key = create_endpoint_server()

    assert random_key in RequestInspector.gen_servers_keys()

    conn =
      conn(:delete, "/#{random_key}", "")
      |> Router.call(@opts)

    assert conn.status == 200
    assert random_key not in RequestInspector.gen_servers_keys()
  end

  test "GET /:key/requests returns the requests made to the /endpoint" do
    random_key = create_endpoint_server()

    # Initial requests list is empty
    initial_conn =
      conn(:get, "/#{random_key}/requests", "")
      |> Router.call(@opts)

    assert initial_conn.status == 200
    requests = Poison.decode!(initial_conn.resp_body)
    assert requests == []

    # Make a request to the endpoint
    endpoint_conn =
      conn(:get, "/#{random_key}/endpoint?foo=bar", "")
      |> Router.call(@opts)

    assert endpoint_conn.status == 200

    # Now the requests list includes the request made
    updated_conn =
      conn(:get, "/#{random_key}/requests", "")
      |> Router.call(@opts)

    requests = Poison.decode!(updated_conn.resp_body)
    [single_req] = requests

    assert length(requests) == 1
    assert single_req |> Map.get("method") == "GET"
    assert single_req |> Map.get("path") == "/#{random_key}/endpoint"
    assert single_req |> Map.get("queryParams") == %{"foo" => "bar"}
  end


  defp create_endpoint_server() do
    initial_conn =
      conn(:post, "/keys")
      |> Router.call(@opts)

    response_map = Poison.decode!(initial_conn.resp_body)
    # Return the key of the newly-created GenServer
    Map.get(response_map, "key")
  end
end
