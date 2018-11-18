defmodule OpenApiSpex.CastContext do
  defstruct value: nil,
            schema: nil,
            schemas: %{},
            path: [],
            index: 0,
            errors: []
end
