defmodule OpenApiSpex.Validation do
  @moduledoc """
  The result of a cast or validation
  """

  defstruct schema: nil,
            schemas: [],
            value: nil,
            error: nil
end
