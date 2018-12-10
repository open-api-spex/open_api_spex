defmodule OpenApiSpex.Operation2 do
  @moduledoc """
  Defines the `OpenApiSpex.Operation.t` type.
  """
  alias OpenApiSpex.{
    Cast,
    Operation,
    Parameter,
    RequestBody,
    Schema
  }

  alias Plug.Conn

  alias OpenApiSpex.Cast.Error

  @spec cast(Operation.t(), Conn.t(), String.t() | nil, Schema.schemas()) ::
          {:error, [Error.t()]} | {:ok, Conn.t()}
  def cast(operation = %Operation{}, conn = %Conn{}, content_type, schemas) do
    with {:ok, conn} <- cast_query_parameters(conn, operation, schemas),
         {:ok, body} <-
           cast_request_body(operation.requestBody, conn.body_params, content_type, schemas) do
      {:ok, %{conn | body_params: body}}
    end
  end

  ## Private functions

  defp cast_query_parameters(conn, operation, schemas) do
    parameters =
      Enum.filter(operation.parameters || [], fn p ->
        Map.has_key?(conn.params, Atom.to_string(p.name))
      end)

    with :ok <- check_query_params_defined(conn, operation.parameters),
         {:ok, parameter_values} <- cast_parameters(parameters, conn.params, schemas),
         conn = %{conn | params: parameter_values},
         parameters =
           Enum.filter(operation.parameters || [], &Map.has_key?(conn.params, &1.name)),
         :ok <- validate_parameter_schemas(parameters, conn.params, schemas) do
      {:ok, %{conn | params: parameter_values}}
    end
  end

  defp check_query_params_defined(%Conn{}, nil = _defined_params) do
    :ok
  end

  defp check_query_params_defined(%Conn{} = conn, defined_params)
       when is_list(defined_params) do
    defined_query_params =
      for param <- defined_params,
          param.in == :query,
          into: MapSet.new(),
          do: to_string(param.name)

    case validate_parameter_keys(Map.keys(conn.query_params), defined_query_params) do
      {:error, name} -> {:error, [%Error{reason: :unexpected_field, name: name}]}
      :ok -> :ok
    end
  end

  defp validate_parameter_keys([], _defined_params), do: :ok

  defp validate_parameter_keys([name | params], defined_params) do
    case MapSet.member?(defined_params, name) do
      false -> {:error, name}
      _ -> validate_parameter_keys(params, defined_params)
    end
  end

  defp cast_parameters([], _params, _schemas), do: {:ok, %{}}

  defp cast_parameters([p | rest], params = %{}, schemas) do
    with {:ok, cast_val} <-
           Cast.cast(Parameter.schema(p), params[Atom.to_string(p.name)], schemas),
         {:ok, cast_tail} <- cast_parameters(rest, params, schemas) do
      {:ok, Map.put_new(cast_tail, p.name, cast_val)}
    end
  end

  defp validate_parameter_schemas([], %{} = _params, _schemas), do: :ok

  defp validate_parameter_schemas([p | rest], %{} = params, schemas) do
    {:ok, parameter_value} = Map.fetch(params, p.name)

    with {:ok, _value} <- Cast.cast(Parameter.schema(p), parameter_value, schemas) do
      validate_parameter_schemas(rest, params, schemas)
    end
  end

  defp cast_request_body(nil, _, _, _), do: {:ok, %{}}

  defp cast_request_body(%RequestBody{content: content}, params, content_type, schemas) do
    schema = content[content_type].schema
    Cast.cast(schema, params, schemas)
  end
end
