defmodule OpenApiSpex.CastContext do
  defstruct value: nil,
            schema: nil,
            schemas: %{},
            path: [],
            key: nil,
            index: 0,
            errors: []
end
