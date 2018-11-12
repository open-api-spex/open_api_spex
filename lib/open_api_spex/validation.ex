defmodule OpenApiSpex.Validation do
  @moduledoc """
  The result of a cast or validation
  """

  alias OpenApiSpex.Schema

  @type t :: %__MODULE__{}

  defstruct schema: nil,
            schemas: [],
            value: nil,
            errors: [],
            path: []

  def new(value, %Schema{} = schema, %{} = schemas \\ %{}) do
    %__MODULE__{schema: schema, value: value, schemas: schemas}
  end
end
