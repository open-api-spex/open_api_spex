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

    assert SchemaCreate.__struct__()
  end

  defmodule SchemaWithoutStructDef do
    require OpenApiSpex

    OpenApiSpex.schema(%{type: :string}, struct?: false)
  end

  test "able to define schema without defining a struct" do
    assert_raise UndefinedFunctionError, fn ->
      SchemaWithoutStructDef.__struct__()
    end
  end

  defmodule SchemaWithoutDerive do
    require OpenApiSpex

    OpenApiSpex.schema(%{type: :string}, derive?: false)
  end

  test "able to define schema module without a @derive" do
    assert_raise Protocol.UndefinedError, fn ->
      struct = %SchemaWithoutDerive{}
      Jason.encode!(struct)
    end
  end
end
