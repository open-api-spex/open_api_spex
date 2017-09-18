defmodule OpenApiSpex do
  alias OpenApiSpex.{OpenApi, RequestBody, Schema, SchemaResolver}
  alias Plug.Conn

  @moduledoc """
  """
  def resolve_schema_modules(spec = %OpenApi{}) do
    SchemaResolver.resolve_schema_modules(spec)
  end

  def cast_parameters(conn = %Conn{}, operation_id) do
    operation = conn.private.open_api_spex.operation_lookup[operation_id]
    spec = conn.private.open_api_spex.spec
    schemas = spec.components.schemas

    params =
      operation.parameters
      |> Enum.filter(fn parameter -> Map.has_key?(conn.params, Atom.to_string(parameter.name)) end)
      |> Enum.map(fn %{schema: schema, name: name} -> {name, Schema.cast(schema, conn.params[name], schemas)} end)
      |> Enum.reduce({:ok, %{}}, fn
          {name, {:ok, val}}, {:ok, acc} -> {:ok, Map.put(acc, name, val)}
          _, {:error, reason} -> {:error, reason}
          {_name, {:error, reason}}, _ -> {:error, reason}
        end)

    body = case operation.requestBody do
      nil -> {:ok, %{}}
      %RequestBody{content: content} ->
        [content_type] = Conn.get_req_header(conn, "content-type")
        schema = content[content_type].schema
        Schema.cast(schema, conn.params, spec.components.schemas)
    end

    with {:ok, cast_params} <- params,
         {:ok, cast_body} <- body do
      params = Map.merge(cast_params, cast_body)
      {:ok, %{conn | params: params}}
    end
  end
end
