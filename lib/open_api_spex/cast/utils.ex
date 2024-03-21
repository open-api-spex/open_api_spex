defmodule OpenApiSpex.Cast.Utils do
  @moduledoc false

  alias OpenApiSpex.Cast.Error

  # Merge 2 maps considering as equal keys that are atom or string representation
  # of that atom. Atom keys takes precedence over string ones.
  def merge_maps(map1, map2) do
    result = Map.merge(map1, map2)

    Enum.reduce(result, result, fn
      {k, _v}, result when is_atom(k) -> Map.delete(result, to_string(k))
      _, result -> result
    end)
  end

  def check_required_fields(%{value: input_map} = ctx), do: check_required_fields(ctx, input_map)

  def check_required_fields(ctx, %{} = input_map) do
    required = Map.get(ctx.schema, :required) || []

    # Adjust required fields list, based on read_write_scope
    required =
      Enum.filter(required, fn key ->
        case {ctx.read_write_scope, ctx.schema.properties[key]} do
          {:read, %{writeOnly: true}} -> false
          {:write, %{readOnly: true}} -> false
          _ -> true
        end
      end)

    input_keys = Map.keys(input_map)
    missing_keys = required -- input_keys

    if missing_keys == [] do
      :ok
    else
      errors =
        Enum.map(missing_keys, fn key ->
          ctx = %{ctx | path: [key | ctx.path]}
          Error.new(ctx, {:missing_field, key})
        end)

      {:error, ctx.errors ++ errors}
    end
  end

  def check_required_fields(_ctx, _acc), do: :ok

  @doc """
  Retrieves the content type from the request header of the given connection.

  ## Parameters:

    - `conn`: The connection from which the content type should be retrieved. Must be an instance of `Plug.Conn`.

  ## Returns:

    - If the content type is found: Returns the main content type as a string. For example, for the header "application/json; charset=utf-8", it would return "application/json".
    - If the content type is not found or is not set: Returns `nil`.

  ## Examples:

      iex> content_type_from_header(%Plug.Conn{req_headers: [{"content-type", "application/json; charset=utf-8"}]})
      "application/json"

      iex> content_type_from_header(%Plug.Conn{req_headers: []})
      nil

  ## Notes:

  - The function only retrieves the main content type and does not consider any additional parameters that may be set in the `content-type` header.
  - If multiple `content-type` headers are found, the function will only return the value of the first one.

  """
  @spec content_type_from_header(Plug.Conn.t(), :request | :response) ::
          String.t() | nil
  def content_type_from_header(conn = %Plug.Conn{}, header_location \\ :request) do
    content_type =
      case header_location do
        :request ->
          Plug.Conn.get_req_header(conn, "content-type")

        :response ->
          Plug.Conn.get_resp_header(conn, "content-type")
      end

    case content_type do
      [header_value | _] ->
        header_value
        |> String.split(";")
        |> List.first()

      _ ->
        nil
    end
  end
end
