defmodule OpenApiSpex.Operation2 do
  @moduledoc """
  Casts and validates a request from a Plug conn.
  """
  alias OpenApiSpex.{
    Cast,
    CastParameters,
    Operation,
    RequestBody,
    Schema
  }

  alias OpenApiSpex.Cast.Error
  alias Plug.Conn

  @spec cast(Operation.t(), Conn.t(), String.t() | nil, Schema.schemas()) ::
          {:error, [Error.t()]} | {:ok, Conn.t()}
  def cast(operation = %Operation{}, conn = %Conn{}, content_type, schemas) do
    with {:ok, conn} <- cast_parameters(conn, operation, schemas),
         {:ok, body} <-
           cast_request_body(operation.requestBody, conn.body_params, content_type, schemas) do
      {:ok, %{conn | body_params: body}}
    end
  end

  ## Private functions

  defp cast_parameters(conn, operation, schemas) do
    CastParameters.cast(conn, operation, schemas)
  end

  defp cast_request_body(%RequestBody{} = request_body_spec, params, content_type, schemas) do
    with {:ok, content_type} <- validate_content_type(content_type),
         {:ok, schema} <- fetch_schema(request_body_spec, content_type) do
      Cast.cast(schema, params, schemas)
    else
      {:error, :missing_content_type} ->
        if request_body_spec.required do
          {:error, [:missing_content_type]}
        else
          {:ok, %{}}
        end

      {:error, reason} ->
        {:error, [reason]}
    end
  end

  defp cast_request_body(_, _, _, _), do: {:ok, %{}}

  defp validate_content_type(content_type) when is_binary(content_type) do
    case content_type do
      "" -> {:error, :missing_content_type}
      _ -> {:ok, content_type}
    end
  end

  defp validate_content_type(nil) do
    {:error, :missing_content_type}
  end

  defp validate_content_type(_content_type) do
    {:error, :expected_binary_for_content_type}
  end

  defp fetch_schema(%RequestBody{content: content}, content_type) do
    with %{^content_type => %{schema: schema}} <- content do
      {:ok, schema}
    else
      _ -> {:error, :unexpected_content_type}
    end
  end
end
