defmodule RequestInspector.RouterTest do
  alias RequestInspector.Router
  use ExUnit.Case
  use Plug.Test

  require IEx

  @opts Router.init([])

  setup do
    Application.ensure_all_started(:request_inspector)
    :ok
  end


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
    initial_conn =
      conn(:get, "/requests", "")
      |> Router.call(@opts)

    assert initial_conn.status == 200
    assert Poison.decode!(initial_conn.resp_body) == []
  end
end