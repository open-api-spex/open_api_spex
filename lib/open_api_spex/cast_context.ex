defmodule OpenApiSpex.CastContext do
  alias OpenApiSpex.CastError

  defstruct value: nil,
            schema: nil,
            schemas: %{},
            path: [],
            key: nil,
            index: 0,
            errors: []

  def error(ctx, error_args) do
    error = CastError.new(ctx, error_args)
    {:error, [error | ctx.errors]}
  end
end
