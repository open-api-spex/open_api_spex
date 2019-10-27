defmodule OpenApiSpex.TestAssertions do
  @moduledoc """
  Defines helpers for testing API responses and examples against API spec schemas.
  """
  import ExUnit.Assertions
  alias OpenApiSpex.OpenApi
  alias OpenApiSpex.Cast.Error

  @dialyzer {:no_match, assert_schema: 3}

  @doc """
  Asserts that `value` conforms to the schema with title `schema_title` in `api_spec`.
  """
  @spec assert_schema(term, String.t(), OpenApi.t()) :: term | no_return
  def assert_schema(value, schema_title, api_spec = %OpenApi{}) do
    schemas = api_spec.components.schemas
    schema = schemas[schema_title]

    if !schema do
      flunk("Schema: #{schema_title} not found in #{inspect(Map.keys(schemas))}")
    end

    case OpenApiSpex.cast_value(value, schema, api_spec) do
      {:ok, data} ->
        data

      {:error, errors} ->
        errors =
          Enum.map(errors, fn error ->
            message = Error.message(error)
            path = Error.path_to_string(error)
            "#{message} at #{path}"
          end)

        flunk(
          "Value does not conform to schema #{schema_title}: #{Enum.join(errors, "\n")}\n#{
            inspect(value)
          }"
        )
    end
  end
end
