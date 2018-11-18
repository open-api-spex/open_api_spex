defmodule OpenApiSpex.CastContext do
  defstruct value: nil,
            schema: nil,
            schemas: %{},
            path: [],
            errors: []
end
