defmodule OpenApiSpex.Cast do
  alias OpenApiSpex.{CastArray, CastContext, CastObject, CastPrimitive}
  @primitives [:boolean, :integer, :number, :string]

  def cast(value, schema, schemas \\ nil)

  def cast(value, nil, _schemas), do: {:ok, value}

  def cast(value, %{type: type} = schema, schemas) when type in @primitives do
    ctx = %CastContext{value: value, schema: schema, schemas: schemas}
    CastPrimitive.cast(ctx)
  end

  def cast(value, %{type: :array} = schema, schemas) do
    ctx = %CastContext{value: value, schema: schema, schemas: schemas}
    CastArray.cast(ctx)
  end

  def cast(value, %{type: :object} = schema, schemas),
    do: CastObject.cast(value, schema, schemas)
end
