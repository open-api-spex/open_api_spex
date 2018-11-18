defmodule OpenApiSpex.CastString do
  @moduledoc false
  alias OpenApiSpex.CastContext

  def cast(%{value: value, schema: %{pattern: pattern}} = ctx)
      when not is_nil(pattern) and is_binary(value) do
    if Regex.match?(pattern, value) do
      {:ok, value}
    else
      CastContext.error(ctx, {:invalid_format, pattern})
    end
  end

  def cast(%{value: value}) when is_binary(value) do
    {:ok, value}
  end

  def cast(ctx) do
    CastContext.error(ctx, {:invalid_type, :string})
  end
end
