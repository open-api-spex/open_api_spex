defmodule OpenApiSpex.SchemaConstructionTest do
  use ExUnit.Case

  defmodule SchemaCreate do
    require OpenApiSpex

    OpenApiSpex.schema(%OpenApiSpex.Schema{type: :string})
  end

  defmodule SchemaWithModuledoc do
    @moduledoc "sample moduledoc"

    require OpenApiSpex

    OpenApiSpex.schema(%OpenApiSpex.Schema{
      title: "Lines of code",
      description: "How many lines of code were written today",
      type: :integer
    })

    def doc, do: @moduledoc
  end

  defmodule SchemaWithoutModuledoc do
    require OpenApiSpex

    OpenApiSpex.schema(%OpenApiSpex.Schema{
      title: "Lines of code",
      description: "How many lines of code were written today",
      type: :integer
    })

    def doc, do: @moduledoc
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

  test "preserves the moduledoc" do
    assert "sample moduledoc" = SchemaWithModuledoc.doc()
  end

  test "generates a moduledoc from the schema" do
    assert "Lines of code\n\nHow many lines of code were written today" =
             SchemaWithoutModuledoc.doc()
  end

  defmodule SchemaWithOneOf do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      oneOf: [
        %OpenApiSpex.Schema{type: :object, properties: %{str_prop: %OpenApiSpex.Schema{type: :string}}},
        %OpenApiSpex.Schema{type: :object, properties: %{int_prop: %OpenApiSpex.Schema{type: :integer}}}
      ]
    })
  end

  test "can create structs for schemas defined using oneOf" do
    schema_keys = SchemaWithOneOf.__struct__() |> Map.keys()
    assert :str_prop in schema_keys
    assert :int_prop in schema_keys
  end
end
