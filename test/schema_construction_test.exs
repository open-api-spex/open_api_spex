defmodule OpenApiSpex.SchemaConstructionTest do
  use ExUnit.Case

  defmodule SchemaCreate do
    require OpenApiSpex

    OpenApiSpex.schema(%OpenApiSpex.Schema{type: :string})
  end

  test "calling schema() macro works with a struct" do
    assert %OpenApiSpex.Schema{"x-struct": module, type: schema_type} = SchemaCreate.schema()
    assert schema_type == :string
    assert module == SchemaCreate
  end
end
