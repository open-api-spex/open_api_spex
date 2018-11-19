defmodule OpenApiSpex.Cast.Context do
  alias OpenApiSpex.Cast.Error

  defstruct value: nil,
            schema: nil,
            schemas: %{},
            path: [],
            key: nil,
            index: 0,
            errors: []

  def error(ctx, error_args) do
    error = Error.new(ctx, error_args)
    {:error, [error | ctx.errors]}
  end
end
