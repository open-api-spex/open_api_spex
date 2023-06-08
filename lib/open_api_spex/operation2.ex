defmodule OpenApiSpex.Operation2 do
  @moduledoc """
  Casts and validates a request from a Plug conn.
  """
  alias OpenApiSpex.{
    Cast,
    CastParameters,
    Components,
    OpenApi,
    Operation,
    Reference,
    RequestBody
  }

  alias OpenApiSpex.Cast.Error
  alias Plug.Conn

  @spec cast(
          OpenApi.t(),
          Operation.t(),
          Conn.t(),
          String.t() | nil,
          opts :: [OpenApiSpex.cast_opt()]
        ) ::
          {:error, [Error.t()]} | {:ok, Conn.t()}
  def cast(
        spec = %OpenApi{components: components},
        operation = %Operation{},
        conn = %Conn{},
        content_type,
        opts \\ []
      ) do
    replace_params = Keyword.get(opts, :replace_params, true)

    with {:ok, conn} <- cast_parameters(conn, operation, spec, opts),
         {:ok, body} <-
           cast_request_body(
             operation.requestBody,
             conn.body_params,
             content_type,
             components,
             opts
           ) do
      {:ok,
       conn
       |> cast_conn(body)
       |> maybe_replace_body(body, replace_params)
       |> put_operation_id(operation)}
    end
  end

  ## Private functions

  defp put_operation_id(conn, operation) do
    private_data =
      conn
      |> Map.get(:private)
      |> Map.get(:open_api_spex, %{})
      |> Map.put(:operation_id, operation.operationId)

    Plug.Conn.put_private(conn, :open_api_spex, private_data)
  end

  defp cast_conn(conn, body) do
    private_data =
      conn
      |> Map.get(:private)
      |> Map.get(:open_api_spex, %{})
      |> Map.put(:body_params, body)

    Plug.Conn.put_private(conn, :open_api_spex, private_data)
  end

  defp maybe_replace_body(conn, _body, false), do: conn
  defp maybe_replace_body(conn, body, true), do: %{conn | body_params: body}

  defp cast_parameters(conn, operation, spec, opts) do
    CastParameters.cast(conn, operation, spec, opts)
  end

  defp cast_request_body(ref = %Reference{}, body_params, content_type, components, opts) do
    request_body = Reference.resolve_request_body(ref, components.requestBodies)

    cast_request_body(request_body, body_params, content_type, components, opts)
  end

  defp cast_request_body(nil, _, _, _, _), do: {:ok, %{}}

  defp cast_request_body(%{required: false}, _, nil, _, _), do: {:ok, %{}}

  defp cast_request_body(%{required: true}, _, nil, _, _) do
    {:error, [Error.new(%{path: [], value: nil}, {:missing_header, "content-type"})]}
  end

  # Special case to handle strings or arrays in request body that come inside _json
  # https://hexdocs.pm/plug/Plug.Parsers.JSON.html
  defp cast_request_body(
         request_body,
         %{"_json" => body_params},
         content_type,
         components = %Components{},
         opts
       ) do
    case cast_request_body(request_body, body_params, content_type, components, opts) do
      {:ok, body_params} -> {:ok, %{"_json" => body_params}}
      error -> error
    end
  end

  defp cast_request_body(
         %RequestBody{content: content},
         params,
         content_type,
         components = %Components{},
         opts
       ) do
    case content do
      %{^content_type => media_type} ->
        Cast.cast(media_type.schema, params, components.schemas, opts)

      _ ->
        {:error, [Error.new(%{path: [], value: content_type}, {:invalid_header, "content-type"})]}
    end
  end
end
