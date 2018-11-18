defmodule OpenApiSpex.CastContext do
  alias OpenApiSpex.Error

  defstruct value: nil,
            schema: nil,
            schemas: %{},
            path: [],
            key: nil,
            index: 0,
            errors: []

  def error(ctx, {:invalid_type, type}) do
    error = Error.new(:invalid_type, type, ctx.value)
    error = %{error | path: Enum.reverse(ctx.path)}
    {:error, [error | ctx.errors]}
  end

  def error(ctx, {:invalid_format, format}) do
    error = Error.new(:invalid_format, format, ctx.value)
    error = %{error | path: Enum.reverse(ctx.path)}
    {:error, [error | ctx.errors]}
  end
end
