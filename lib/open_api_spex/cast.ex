defmodule OpenApiSpex.Cast do
  alias OpenApiSpex.Reference
  alias OpenApiSpex.Cast.{Array, Error, Object, Primitive, String}

  defstruct value: nil,
            schema: nil,
            schemas: %{},
            path: [],
            key: nil,
            index: 0,
            errors: []

  def cast(schema, value, schemas) do
    ctx = %__MODULE__{schema: schema, value: value, schemas: schemas}
    cast(ctx)
  end

  # nil schema
  def cast(%__MODULE__{value: value, schema: nil}),
    do: {:ok, value}

  def cast(%__MODULE__{schema: %Reference{}} = ctx) do
    schema = Reference.resolve_schema(ctx.schema, ctx.schemas)
    cast(%{ctx | schema: schema})
  end

  # nullable: true
  def cast(%__MODULE__{value: nil, schema: %{nullable: true}}) do
    {:ok, nil}
  end

  # nullable: false
  def cast(%__MODULE__{value: nil} = ctx) do
    error(ctx, {:null_value})
  end

  # Enum
  def cast(%__MODULE__{schema: %{enum: []}} = ctx) do
    cast(%{ctx | enum: nil})
  end

  # Enum
  def cast(%__MODULE__{schema: %{enum: enum}} = ctx) when is_list(enum) do
    with {:ok, value} <- cast(%{ctx | schema: %{ctx.schema | enum: nil}}) do
      if value in enum do
        {:ok, value}
      else
        error(ctx, {:invalid_enum})
      end
    end
  end

  ## Specific types

  def cast(%__MODULE__{schema: %{type: :boolean}} = ctx),
    do: Primitive.cast_boolean(ctx)

  def cast(%__MODULE__{schema: %{type: :integer}} = ctx),
    do: Primitive.cast_integer(ctx)

  def cast(%__MODULE__{schema: %{type: :number}} = ctx),
    do: Primitive.cast_number(ctx)

  def cast(%__MODULE__{schema: %{type: :string}} = ctx),
    do: String.cast(ctx)

  def cast(%__MODULE__{schema: %{type: :array}} = ctx),
    do: Array.cast(ctx)

  def cast(%__MODULE__{schema: %{type: :object}} = ctx),
    do: Object.cast(ctx)

  def cast(%__MODULE__{schema: %{type: _other}} = ctx),
    do: error(ctx, {:invalid_schema_type})

  def cast(%{} = ctx), do: cast(struct(__MODULE__, ctx))
  def cast(ctx) when is_list(ctx), do: cast(struct(__MODULE__, ctx))

  # Add an error
  def error(ctx, error_args) do
    error = Error.new(ctx, error_args)
    {:error, [error | ctx.errors]}
  end
end
