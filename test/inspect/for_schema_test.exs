defmodule OpenApiSpex.Inspect.ForSchemaTest do
  use ExUnit.Case, async: true
  alias OpenApiSpex.Schema

  test "inspect schema" do
    schema = %Schema{title: "Hello"}
    output = inspect(schema)
    assert output == "%OpenApiSpex.Schema{title: \"Hello\"}"
  end
end
