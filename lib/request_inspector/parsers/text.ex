# Custom parser for dealing with text (text/*)
defmodule RequestsInspector.Parsers.Text do
  @behaviour Plug.Parsers

  import Plug.Conn, only: [read_body: 1]


  def init(opts), do: opts

  # Parse text/* requests by extracting the body as a string and putting it in a
  # dictionary with the key: :text
  def parse(conn, "text", _subtype, _headers, _opts) do
    {:ok, body_string, updated_conn} = read_body(conn)
    body_params = %{text: body_string}
    
    {:ok, body_params, updated_conn}
  end

  # Default guard if the type is not "text"
  def parse(conn, _type, _subtype, _headers, _opts), do:  {:next, conn}
end