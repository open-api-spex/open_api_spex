defmodule OpenApiSpex.Validation do
  @moduledoc """
  The result of a cast or validation
  """

  @type t :: %__MODULE__{}

  defstruct schema: nil,
            schemas: [],
            value: nil,
            errors: []
end
