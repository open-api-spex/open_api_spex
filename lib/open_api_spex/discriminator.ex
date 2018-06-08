defmodule OpenApiSpex.Discriminator do
  @moduledoc """
  Defines the `OpenApiSpex.Discriminator.t` type.
  """

  @enforce_keys :propertyName
  defstruct [
    :propertyName,
    :mapping
  ]

  @typedoc """
  [Discriminator Object](https://swagger.io/specification/#discriminatorObject)

  When request bodies or response payloads may be one of a number of different schemas,
  a discriminator object can be used to aid in serialization, deserialization, and validation.
  The discriminator is a specific object in a schema which is used to inform the consumer of the
  specification of an alternative schema based on the value associated with it.
  """
  @type t :: %__MODULE__{
    propertyName: String.t,
    mapping: %{String.t => String.t} | nil
  }
end
