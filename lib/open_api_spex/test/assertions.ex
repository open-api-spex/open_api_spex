defmodule OpenApiSpex.Test.Assertions do
  alias OpenApiSpex.OpenApi
  import ExUnit.Assertions

  def assert_schema(value = %{}, schema_title, api_spec = %OpenApi{}) do
    schemas = api_spec.components.schemas
    schema = schemas[schema_title]
    if !schema do
      flunk("Schema: #{schema_title} not found in #{inspect(Map.keys(schemas))}")
    end

    assert {:ok, data} = OpenApiSpex.cast(api_spec, schema, value)
    assert :ok = OpenApiSpex.validate(api_spec, schema, data)
  end
end