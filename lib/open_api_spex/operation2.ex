defmodule OpenApiSpex.Operation2 do
  @moduledoc """
  Casts and validates a request from a Plug conn.
  """
  alias OpenApiSpex.{
    Cast,
    CastParameters,
    Operation,
    RequestBody,
    Components
  }

  alias OpenApiSpex.Cast.Error
  alias Plug.Conn

  @spec cast(Operation.t(), Conn.t(), String.t() | nil, Components.t()) ::
          {:error, [Error.t()]} | {:ok, Conn.t()}
  def cast(operation = %Operation{}, conn = %Conn{}, content_type, components = %Components{}) do
    with {:ok, conn} <- cast_parameters(conn, operation, components),
         {:ok, body} <-
           cast_request_body(operation.requestBody, conn.body_params, content_type, components) do
      {:ok, %{conn | body_params: body}}
    end
  end

  ## Private functions

  defp cast_parameters(conn, operation, components) do
    CastParameters.cast(conn, operation, components)
  end

  defp cast_request_body(nil, _, _, _), do: {:ok, %{}}

  defp cast_request_body(%{required: false}, _, nil, _), do: {:ok, %{}}

  defp cast_request_body(%{required: true}, _, nil, _) do
    {:error, [Error.new(%{path: [], value: nil}, {:missing_header, "content-type"})]}
  end

  defp cast_request_body(%RequestBody{content: content}, params, content_type, components = %Components{}) do
    case content do
      %{^content_type => media_type} ->
        Cast.cast(media_type.schema, params, components.schemas)

      _ ->
        {:error, [Error.new(%{path: [], value: content_type}, {:invalid_header, "content-type"})]}
    end
  end
end
