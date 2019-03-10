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

  defp cast_request_body(nil, _, _, _), do: {:ok, %{}}

  defp cast_request_body(%RequestBody{content: content}, params, content_type, schemas) do
    schema = content[content_type].schema
    Cast.cast(schema, params, schemas)
  end
end
