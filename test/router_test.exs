defmodule RequestInspector.RouterTest do
  alias RequestInspector.Router
  use ExUnit.Case
  use Plug.Test

  @opts Router.init([])

  test "GET / returns the index.html page" do
    root_conn = 
      conn(:get, "/", "")
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

  test "GET /requests returns the requests made to the endpoint" do
    # Initial requests list is empty
    initial_conn =
      conn(:get, "/requests", "")
      |> Router.call(@opts)

    assert initial_conn.status == 200
    requests = Poison.decode!(initial_conn.resp_body)
    assert requests == []

    # Make a request to the endpoint
    endpoint_conn =
      conn(:get, "/endpoint?foo=bar", "")
      |> Router.call(@opts)

    assert endpoint_conn.status == 200

    # Now the requests list includes the request made
    updated_conn =
      conn(:get, "/requests", "")
      |> Router.call(@opts)

    requests = Poison.decode!(updated_conn.resp_body)
    [single_req] = requests

    assert length(requests) == 1
    assert single_req |> Map.get("method") == "GET"
    assert single_req |> Map.get("path") == "/endpoint"
    assert single_req |> Map.get("queryParams") == %{"foo" => "bar"}
  end
end