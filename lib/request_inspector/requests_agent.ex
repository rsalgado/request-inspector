defmodule RequestInspector.RequestsAgent do
  @moduledoc """
  Agent for storing (in memory) the requests made to the endpoint
  """

  require Logger

  use Agent

  def start_link(opts) do
    Logger.debug("Starting requests agent")
    Agent.start_link(fn -> %{counter: 0, requests: []} end, opts)
  end

  @doc """
  Takes a map (with the request info), adds an `:id` and `:time` timestamp to it, and stores it
  at the top of the `:requests` list in the `agent`
  """
  @spec store_request(map, pid) :: map
  def store_request(request, agent) do
    # Get a new id for the request
    id = new_id(agent)
    # and store it at the top of the list with the current time
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
    Logger.debug("RequestsAgent #{inspect self()} length: #{count} items")
    # Return updated request (with id and time)
    updated_req
  end

  @spec get_requests(pid) :: [map]
  def get_requests(agent) do
    Agent.get(agent, fn(%{requests: reqs}) ->  reqs end)
  end

  @doc """
  Generates a new id. This *both* gets and updates the incremental `:counter` used for ids
  """
  @spec new_id(pid) :: integer
  def new_id(agent) do
    Agent.get_and_update(agent, fn(map) ->
      counter = Map.get(map, :counter)
      new_map = Map.put(map, :counter, counter + 1)
      # Return a tuple (first element is the 'get' response, second is the 'update'-d state)
      {counter, new_map}
    end)
  end
end
