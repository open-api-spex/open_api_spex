defmodule OpenApiSpex.Test.Assertions2 do
  @moduledoc """
  Defines helpers for testing API responses and examples against API spec schemas.
  """

  @doc """
  Asserts that `value` conforms to the schema with title `schema_title` in `api_spec`.
  """
  @spec assert_schema(map, String.t(), OpenApi.t()) :: map | no_return
  @deprecated "Use OpenApiSpex.TestAssertions.assert_schema/3 instead"
  defdelegate assert_schema(value, schema_title, api_spec), to: OpenApiSpex.TestAssertions
end
