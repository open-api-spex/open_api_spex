defmodule OpenApiSpex.Cast.String do
  @moduledoc false
  alias OpenApiSpex.Cast.Context

  def cast(%{value: value} = ctx) when is_binary(value) do
    cast_binary(ctx)
  end

  def cast(ctx) do
    Context.error(ctx, {:invalid_type, :string})
  end

  ## Private functions

  defp cast_binary(%{value: value, schema: %{pattern: pattern}} = ctx) when not is_nil(pattern) do
    if Regex.match?(pattern, value) do
      {:ok, value}
    else
      Context.error(ctx, {:invalid_format, pattern})
    end
  end

  defp cast_binary(%{value: value, schema: %{minLength: min_length}} = ctx)
       when is_integer(min_length) do
    # Note: This is not part of the JSON Shema spec: trim string before measuring length
    # It's just too important to miss
    trimmed = String.trim(value)
    length = String.length(trimmed)

    if length < min_length do
      Context.error(ctx, {:min_length, length})
    else
      {:ok, value}
    end
  end

  defp cast_binary(%{value: value}) do
    {:ok, value}
  end
end
