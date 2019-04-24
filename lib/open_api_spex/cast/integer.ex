defmodule OpenApiSpex.Cast.Integer do
  @moduledoc false
  alias OpenApiSpex.Cast

  def cast(%{value: value} = ctx) when is_integer(value) do
    case cast_integer(ctx) do
      {:cast, ctx} -> cast(ctx)
      result -> result
    end
  end

  def cast(%{value: value} = ctx) when is_number(value) do
    cast(%{ctx | value: round(value)})
  end

  def cast(%{value: value} = ctx) when is_binary(value) do
    case Float.parse(value) do
      {value, ""} -> cast(%{ctx | value: value})
      _ -> Cast.error(ctx, {:invalid_type, :integer})
    end
  end

  def cast(ctx) do
    Cast.error(ctx, {:invalid_type, :integer})
  end

  ## Private functions

  defp cast_integer(%{value: value, schema: %{minimum: minimum, exclusiveMinimum: true}} = ctx)
       when is_integer(value) and is_integer(minimum) do
    if value > minimum do
      Cast.success(ctx, [:minimum, :exclusiveMinimum])
    else
      Cast.error(ctx, {:exclusive_min, minimum, value})
    end
  end

  defp cast_integer(%{value: value, schema: %{minimum: minimum}} = ctx)
       when is_integer(value) and is_integer(minimum) do
    if value >= minimum do
      Cast.success(ctx, :minimum)
    else
      Cast.error(ctx, {:minimum, minimum, value})
    end
  end

  defp cast_integer(%{value: value, schema: %{maximum: maximum, exclusiveMaximum: true}} = ctx)
       when is_integer(value) and is_integer(maximum) do
    if value < maximum do
      Cast.success(ctx, [:maximum, :exclusiveMaximum])
    else
      Cast.error(ctx, {:exclusive_max, maximum, value})
    end
  end

  defp cast_integer(%{value: value, schema: %{maximum: maximum}} = ctx)
       when is_integer(value) and is_integer(maximum) do
    if value <= maximum do
      Cast.success(ctx, :maximum)
    else
      Cast.error(ctx, {:maximum, maximum, value})
    end
  end

  defp cast_integer(%{value: value, schema: %{multipleOf: multiple}} = ctx)
       when is_integer(value) and is_integer(multiple) do
    if Integer.mod(value, multiple) > 0 do
      Cast.error(ctx, {:multiple_of, multiple, value})
    else
      Cast.success(ctx, :multipleOf)
    end
  end

  defp cast_integer(ctx), do: Cast.ok(ctx)
end
