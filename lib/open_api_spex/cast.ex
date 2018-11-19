defmodule OpenApiSpex.Cast do
  alias OpenApiSpex.Reference
  alias OpenApiSpex.Cast.{Array, Context, Object, Primitive}
  @primitives [:boolean, :integer, :number, :string]

  def cast(schema, value, schemas) do
    ctx = %Context{schema: schema, value: value, schemas: schemas}
    cast(ctx)
  end

  # nil schema
  def cast(%Context{value: value, schema: nil}),
    do: {:ok, value}

  def cast(%Context{schema: %Reference{}} = ctx) do
    schema = Reference.resolve_schema(ctx.schema, ctx.schemas)
    cast(%{ctx | schema: schema})
  end

  # nullable: true
  def cast(%Context{value: nil, schema: %{nullable: true}}) do
    {:ok, nil}
  end

  # nullable: false
  def cast(%Context{value: nil} = ctx) do
    Context.error(ctx, {:null_value})
  end

  # Enum
  def cast(%Context{schema: %{enum: []}} = ctx) do
    cast(%{ctx | enum: nil})
  end

  # Enum
  def cast(%Context{schema: %{enum: enum}} = ctx) when is_list(enum) do
    with {:ok, value} <- cast(%{ctx | schema: %{ctx.schema | enum: nil}}) do
      if value in enum do
        {:ok, value}
      else
        Context.error(ctx, {:invalid_enum})
      end
    end
  end

  ## Specific types

  def cast(%Context{schema: %{type: type}} = ctx) when type in @primitives,
    do: Primitive.cast(ctx)

  def cast(%Context{schema: %{type: :array}} = ctx),
    do: Array.cast(ctx)

  def cast(%Context{schema: %{type: :object}} = ctx),
    do: Object.cast(ctx)

  def cast(%{} = ctx), do: cast(struct(Context, ctx))
end
