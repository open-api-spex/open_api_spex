defmodule OpenApiSpex.Cast.String do
  @moduledoc false
  alias OpenApiSpex.Cast

  def cast(%{value: value} = ctx) when is_binary(value) do
    case cast_binary(ctx) do
      {:cast, ctx} -> cast(ctx)
      result -> result
    end
  end

  def cast(ctx) do
    Cast.error(ctx, {:invalid_type, :string})
  end

  ## Private functions

  defp cast_binary(%{value: value, schema: %{format: :"date-time"}} = ctx)
       when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, %DateTime{}, _offset} -> Cast.success(ctx, :format)
      _ -> Cast.error(ctx, {:invalid_format, :"date-time"})
    end
  end

  defp cast_binary(%{value: value, schema: %{format: :date}} = ctx) do
    case Date.from_iso8601(value) do
      {:ok, %Date{}} -> Cast.success(ctx, :format)
      _ -> Cast.error(ctx, {:invalid_format, :date})
    end
  end

  defp cast_binary(%{value: value, schema: %{pattern: pattern}} = ctx) when not is_nil(pattern) do
    if Regex.match?(pattern, value) do
      Cast.success(ctx, :pattern)
    else
      Cast.error(ctx, {:invalid_format, pattern})
    end
  end

  defp cast_binary(%{value: value, schema: %{minLength: min_length}} = ctx)
  when is_integer(min_length) do
    if String.length(value) < min_length do
      Cast.error(ctx, {:min_length, min_length})
    else
      Cast.success(ctx, :minLength)
    end
  end

  defp cast_binary(%{value: value, schema: %{maxLength: max_length}} = ctx)
  when is_integer(max_length) do
    if String.length(value) > max_length do
      Cast.error(ctx, {:max_length, max_length})
    else
      Cast.success(ctx, :maxLength)
    end
  end

  defp cast_binary(ctx), do: Cast.ok(ctx)
end
