defmodule OpenApiSpex.Cast do
  alias OpenApiSpex.{CastArray, CastContext, CastObject, CastPrimitive}
  @primitives [:boolean, :integer, :number, :string]

  def cast(%CastContext{value: value, schema: nil}),
    do: {:ok, value}

  def cast(%CastContext{schema: %{type: type}} = ctx) when type in @primitives,
    do: CastPrimitive.cast(ctx)

  def cast(%CastContext{schema: %{type: :array}} = ctx),
    do: CastArray.cast(ctx)

  def cast(%CastContext{schema: %{type: :object}} = ctx),
    do: CastObject.cast(ctx)

  def cast(%{} = ctx), do: cast(struct(CastContext, ctx))
end
