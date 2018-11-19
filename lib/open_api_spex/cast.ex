defmodule OpenApiSpex.Cast do
  alias OpenApiSpex.{CastArray, CastContext, CastObject, CastPrimitive, Reference}
  @primitives [:boolean, :integer, :number, :string]

  def cast(schema, value, schemas) do
    ctx = %CastContext{schema: schema, value: value, schemas: schemas}
    cast(ctx)
  end

  # nil schema
  def cast(%CastContext{value: value, schema: nil}),
    do: {:ok, value}

  def cast(%CastContext{schema: %Reference{}} = ctx) do
    schema = Reference.resolve_schema(ctx.schema, ctx.schemas)
    cast(%{ctx | schema: schema})
  end

  # nullable: true
  def cast(%CastContext{value: nil, schema: %{nullable: true}}) do
    {:ok, nil}
  end

  # nullable: false
  def cast(%CastContext{value: nil} = ctx) do
    CastContext.error(ctx, {:null_value})
  end

  # Enum
  def cast(%CastContext{schema: %{enum: []}} = ctx) do
    cast(%{ctx | enum: nil})
  end

  # Enum
  def cast(%CastContext{schema: %{enum: enum}} = ctx) when is_list(enum) do
    with {:ok, value} <- cast(%{ctx | schema: %{ctx.schema | enum: nil}}) do
      if value in enum do
        {:ok, value}
      else
        CastContext.error(ctx, {:invalid_enum})
      end
    end
  end

  # Specific types

  def cast(%CastContext{schema: %{type: type}} = ctx) when type in @primitives,
    do: CastPrimitive.cast(ctx)

  def cast(%CastContext{schema: %{type: :array}} = ctx),
    do: CastArray.cast(ctx)

  def cast(%CastContext{schema: %{type: :object}} = ctx),
    do: CastObject.cast(ctx)

  def cast(%{} = ctx), do: cast(struct(CastContext, ctx))
end
