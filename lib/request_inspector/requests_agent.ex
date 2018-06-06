defmodule RequestInspector.RequestsAgent do
  require Logger

  use Agent

  def start_link(opts) do
    Logger.info("Starting RequestsAgent")
    Agent.start_link(fn -> %{counter: 0, requests: []} end, opts)
  end

  def store_request(request, agent) do
    # Use the number of items as id for the request 
    # and store it at the top of the list with the current time
    id = new_id(agent)

    time = DateTime.utc_now() 
            |> DateTime.truncate(:millisecond)
            |> DateTime.to_iso8601()

    updated_req = request
                  |> Map.put(:id, id)
                  |> Map.put(:time, time)

    # Update requests and use the returned map as the new state
    Agent.update(agent, fn(map) ->
      reqs = Map.get(map, :requests)
      Map.put(map, :requests, [updated_req | reqs])
    end)

    count = Agent.get(agent, fn(%{counter: cnt}) -> cnt end)
    Logger.info("RequestsAgent agent length: #{count} items")
    # Return updated request (with id and time)
    updated_req
  end

  def get_requests(agent) do
    Agent.get(agent, fn(%{requests: reqs}) ->  reqs end)
  end

  def new_id(agent) do
    Agent.get_and_update(agent, fn(map) ->
      counter = Map.get(map, :counter)
      new_map = Map.put(map, :counter, counter + 1)
      # Return a tuple (first element is the 'get' response, second is the 'update'-d state)
      {counter, new_map}
    end)
  end
end
