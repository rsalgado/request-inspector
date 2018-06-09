defmodule RequestInspector.EndpointServerTest do
  alias RequestInspector.EndpointServer
  use ExUnit.Case, async: true


  test "Adds GenServer to Registry with the given name" do
    {:ok, _} = Registry.start_link(keys: :unique, name: :test_registry)

    key = "abc123"
    gs_name = {:via, Registry, {:test_registry, key}}
    {:ok, gen_server} = EndpointServer.start_link([], name: gs_name)

    [{pid, _}] = Registry.lookup(:test_registry, key)
    assert pid == gen_server
  end

  test "Creates a server with new agents" do
    {:ok, gen_server} = EndpointServer.start_link []
    {:ok, req_agent} = EndpointServer.get_requests_agent(gen_server)
    {:ok, stream_agent} = EndpointServer.get_stream_agent(gen_server)

    assert Agent.get(req_agent, & &1) == %{counter: 0, requests: []}
    assert Agent.get(stream_agent, & &1) == nil
  end
end