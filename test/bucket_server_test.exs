defmodule RequestInspector.BucketServerTest do
  alias RequestInspector.BucketServer
  use ExUnit.Case, async: true


  test "Can generate random strings with 8 characters" do
    name1 = BucketServer.generate_key()
    name2 = BucketServer.generate_key()

    assert String.length(name1) == String.length(name2)
    assert String.length(name1) == 8
    assert name1 != name2
  end

  test "Adds GenServer to Registry with the given name" do
    {:ok, _} = Registry.start_link(keys: :unique, name: :test_registry)

    key = "abc123"
    gs_name = {:via, Registry, {:test_registry, key}}
    {:ok, gen_server} = BucketServer.start_link([], name: gs_name)

    [{pid, _}] = Registry.lookup(:test_registry, key)
    assert pid == gen_server
  end

  test "Creates a server with new agents" do
    {:ok, gen_server} = BucketServer.start_link []
    {:ok, req_agent} = BucketServer.get_requests_agent(gen_server)
    {:ok, stream_agent} = BucketServer.get_stream_agent(gen_server)

    assert Agent.get(req_agent, & &1) == %{counter: 0, requests: []}
    assert Agent.get(stream_agent, & &1) == nil
  end

  test "Can provide a custom child spec with the correct settings" do
    name = {}
    spec = BucketServer.custom_child_spec(name: name)

    assert spec[:restart] == :transient
    assert spec[:start] == {BucketServer, :start_link, [[], [name: name]]}
  end
end