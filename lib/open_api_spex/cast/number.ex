defmodule OpenApiSpex.Cast.Number do
  @moduledoc false
  alias OpenApiSpex.Cast

  @spec cast(ctx :: Cast.t()) :: {:ok, Cast.t()} | Cast.Error.t()
  def cast(%{value: value} = ctx) when is_number(value) do
    case cast_number(ctx) do
      {:cast, ctx} -> cast(ctx)
      result -> result
    end
  end

  # TODO We need a way to distinguish numbers in (JSON) body vs in request parameters
  # so we can reject strings values for properties of `type: :number`
  def cast(%{value: value} = ctx) when is_binary(value) do
    case Float.parse(value) do
      {value, ""} -> cast(%{ctx | value: value})
      _ -> Cast.error(ctx, {:invalid_type, :number})
    end
  end

  def cast(ctx) do
    Cast.error(ctx, {:invalid_type, :number})
  end

  ## Private functions

  defp cast_number(%{value: value, schema: %{minimum: minimum, exclusiveMinimum: true}} = ctx)
       when is_number(value) and is_number(minimum) do
    if value > minimum do
      Cast.success(ctx, [:minimum, :exclusiveMinimum])
    else
      Cast.error(ctx, {:exclusive_min, minimum, value})
    end
  end

  defp cast_number(%{value: value, schema: %{minimum: minimum}} = ctx)
       when is_number(value) and is_number(minimum) do
    if value >= minimum do
      Cast.success(ctx, :minimum)
    else
      Cast.error(ctx, {:minimum, minimum, value})
    end
  end

  defp cast_number(%{value: value, schema: %{maximum: maximum, exclusiveMaximum: true}} = ctx)
       when is_number(value) and is_number(maximum) do
    if value < maximum do
      Cast.success(ctx, [:maximum, :exclusiveMaximum])
    else
      Cast.error(ctx, {:exclusive_max, maximum, value})
    end
  end

  defp cast_number(%{value: value, schema: %{maximum: maximum}} = ctx)
       when is_number(value) and is_number(maximum) do
    if value <= maximum do
      Cast.success(ctx, :maximum)
    else
      Cast.error(ctx, {:maximum, maximum, value})
    end
  end

  # For now, we don't do anything with `:multipleOf` for properties of `type: :number`
  defp cast_number(ctx), do: Cast.ok(ctx)
end
