defmodule OpenApiSpex.Test.Assertions do
  @moduledoc """
  Defines helpers for testing API responses and examples against API spec schemas.
  """
  alias OpenApiSpex.OpenApi
  import ExUnit.Assertions

  @dialyzer {:no_match, assert_schema: 3}

  @doc """
  Asserts that `value` conforms to the schema with title `schema_title` in `api_spec`.
  """
  @spec assert_schema(map, String.t(), OpenApi.t()) :: map | no_return
  @deprecated "Use OpenApiSpex.TestAssertions.assert_schema/3 instead"
  def assert_schema(value = %{}, schema_title, api_spec = %OpenApi{}) do
    schemas = api_spec.components.schemas
    schema = schemas[schema_title]

    if !schema do
      flunk("Schema: #{schema_title} not found in #{inspect(Map.keys(schemas))}")
    end

    data =
      case Kernel.apply(OpenApiSpex, :cast, [api_spec, schema, value]) do
        {:ok, data} ->
          data

        {:error, reason} ->
          flunk("Value does not conform to schema #{schema_title}: #{reason}\n#{inspect(value)}")
      end

    case Kernel.apply(OpenApiSpex, :validate, [api_spec, schema, value]) do
      :ok ->
        :ok

      {:error, reason} ->
        flunk("Value does not conform to schema #{schema_title}: #{reason}\n#{inspect(value)}")
    end

    data
  end
end
