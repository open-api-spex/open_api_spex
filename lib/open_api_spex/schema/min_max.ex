defmodule OpenApiSpex.Schema.MinMax do
  @moduledoc false

  defstruct [
    :value,
    :exclusive?
  ]

  @type t :: %__MODULE__{
          value: integer,
          exclusive?: boolean | nil
        }
end
