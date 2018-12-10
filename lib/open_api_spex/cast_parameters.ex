defmodule OpenApiSpex.CastParameters do
  @moduledoc false
  alias OpenApiSpex.{Cast, Operation, Parameter, Schema}
  alias OpenApiSpex.Cast.Error
  alias Plug.Conn

  @spec cast(Plug.Conn.t(), Operation.t(), Schema.schemas()) ::
          {:error, [Error.t()]} | {:ok, Conn.t()}
  def cast(conn, operation, schemas) do
    parameters =
      Enum.filter(operation.parameters || [], fn p ->
        Map.has_key?(conn.params, Atom.to_string(p.name))
      end)

    with :ok <- check_query_params_defined(conn, operation.parameters),
         {:ok, parameter_values} <- cast_known_parameters(parameters, conn.params, schemas) do
      {:ok, %{conn | params: parameter_values}}
    end
  end

  ## Private functions

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

  defp cast_known_parameters([], _params, _schemas), do: {:ok, %{}}

  defp cast_known_parameters([p | rest], params = %{}, schemas) do
    with {:ok, cast_val} <-
           Cast.cast(Parameter.schema(p), params[Atom.to_string(p.name)], schemas),
         {:ok, cast_tail} <- cast_known_parameters(rest, params, schemas) do
      {:ok, Map.put_new(cast_tail, p.name, cast_val)}
    end
  end
end
