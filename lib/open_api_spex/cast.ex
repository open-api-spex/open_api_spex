defmodule OpenApiSpex.Cast do
  alias OpenApiSpex.{CastArray, CastObject, CastPrimitive}
  @primitives [:boolean, :integer, :number, :string]

  def cast(value, schema, schemas \\ nil)

  def cast(value, nil, _schemas), do: {:ok, value}

  def cast(value, %{type: type} = schema, _schemas) when type in @primitives do
    CastPrimitive.cast(value, schema)
  end

  def cast(value, %{type: :array} = schema, schemas),
    do: CastArray.cast(value, schema, schemas)

  def cast(value, %{type: :object} = schema, schemas),
    do: CastObject.cast(value, schema, schemas)
end
