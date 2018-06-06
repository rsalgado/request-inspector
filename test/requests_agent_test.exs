defmodule RequestInspector.RequestsAgentTest do
  alias RequestInspector.RequestsAgent
  use ExUnit.Case, async: true

  setup do
    {:ok, agent} = RequestsAgent.start_link []
    %{agent: agent}
  end


  test "Initializes map", %{agent: agent} do
    initial_state = %{counter: 0, requests: []}
    assert Agent.get(agent, & &1) == initial_state
  end

  test "Stores request", %{agent: agent} do
    request = %{method: "GET"}
    RequestsAgent.store_request(request, agent)
    requests = RequestsAgent.get_requests(agent)
    assert length(requests) == 1

    [first_request] = requests
    assert Map.get(first_request, :method) == "GET"
    assert Map.get(first_request, :id) == 0
    assert Map.has_key?(first_request, :time) == true
  end

  test "Increases id number", %{agent: agent} do
    RequestsAgent.new_id(agent)
    RequestsAgent.new_id(agent)
    id = RequestsAgent.new_id(agent)
    assert id == 2
  end

end
