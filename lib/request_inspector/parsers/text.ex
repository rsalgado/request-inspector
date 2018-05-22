# Custom parser for dealing with text
defmodule RequestInspector.Parsers.Text do
  @behaviour Plug.Parsers

  import Plug.Conn, only: [read_body: 1]


  def init(opts), do: opts

  # Parse text requests by extracting the body as a string and putting it in a
  # dictionary with the key: :text
  def parse(conn, type, subtype, _headers, _opts) do
    # Try to handle content as text, or, move on to the next parser
    if is_text?(type, subtype) do
      {:ok, body_string, updated_conn} = read_body(conn)
      body_params = %{text: body_string}

      {:ok, body_params, updated_conn}
    else
      {:next, conn}
    end
  end

  defp is_text?(type, subtype) do
    valid_subtypes = ["plain", "json", "xml", "html", "css", "javascript"]
    type == "text"  ||  subtype in valid_subtypes
  end
end