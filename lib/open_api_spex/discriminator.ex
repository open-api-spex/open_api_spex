defmodule OpenApiSpex.Discriminator do
  @moduledoc """
  Defines the `OpenApiSpex.Discriminator.t` type.
  """

  alias OpenApiSpex.Schema

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
          propertyName: String.t(),
          mapping: %{String.t() => String.t()} | nil
        }

  @doc """
  Resolve the schema that should be used to cast/validate a value using a `Discriminator`.
  """
  @spec resolve(t, map, %{String.t() => Schema.t()}) :: {:ok, Schema.t()} | {:error, String.t()}
  def resolve(%{propertyName: name, mapping: mapping}, value = %{}, schemas = %{}) do
    with {:ok, val} <- get_property_value(value, name) do
      mapped = map_property_value(mapping, val)
      lookup_schema(schemas, mapped)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec get_property_value(map, String.t()) :: {:ok, any} | {:error, String.t()}
  defp get_property_value(value = %{}, property_name) do
    case Map.fetch(value, property_name) do
      {:ok, val} -> {:ok, val}
      :error -> {:error, "No value for required disciminator property: #{property_name}"}
    end
  end

  @spec map_property_value(%{String.t() => String.t()} | nil, String.t()) :: String.t()
  defp map_property_value(nil, val), do: val

  defp map_property_value(mapping = %{}, val) do
    Map.get(mapping, val, val)
  end

  @spec lookup_schema(%{String.t() => Schema.t()}, String.t()) ::
          {:ok, Schema.t()} | {:error, String.t()}
  defp lookup_schema(schemas, "#/components/schemas/" <> name) do
    lookup_schema(schemas, name)
  end

  defp lookup_schema(schemas, name) do
    case Map.fetch(schemas, name) do
      {:ok, schema} -> {:ok, schema}
      :error -> {:error, "Unknown schema: #{name}"}
    end
  end
end
