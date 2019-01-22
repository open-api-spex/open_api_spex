defmodule OpenApiSpex.Test.Assertions2 do
  @moduledoc """
  Defines helpers for testing API responses and examples against API spec schemas.
  """
  alias OpenApiSpex.OpenApi
  alias OpenApiSpex.Cast
  import ExUnit.Assertions

  @dialyzer {:no_match, assert_schema: 3}

  @doc """
  Asserts that `value` conforms to the schema with title `schema_title` in `api_spec`.
  """
  @spec assert_schema(map, String.t(), OpenApi.t()) :: map | no_return
  def assert_schema(value = %{}, schema_title, api_spec = %OpenApi{}) do
    schemas = api_spec.components.schemas
    schema = schemas[schema_title]

    if !schema do
      flunk("Schema: #{schema_title} not found in #{inspect(Map.keys(schemas))}")
    end

    case Cast.cast(schema, value, api_spec.components.schemas) do
      {:ok, data} ->
        data

      {:error, errors} ->
        errors = Enum.map(errors, &to_string/1)

        flunk(
          "Value does not conform to schema #{schema_title}: #{Enum.join(errors, "\n")}\n#{
            inspect(value)
          }"
        )
    end
  end
end
