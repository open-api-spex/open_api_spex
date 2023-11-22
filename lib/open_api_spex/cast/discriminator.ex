defmodule OpenApiSpex.Cast.Discriminator do
  @moduledoc """
  Defines the `OpenApiSpex.Discriminator.t` type.
  """

  alias OpenApiSpex.{Cast, Reference, Schema}

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

  A discriminator requires a composite key be set on the schema:

    * `allOf`
    * `oneOf`
    * `anyOf`
  """
  @type t :: %__MODULE__{
          propertyName: String.t(),
          mapping: %{String.t() => String.t()} | nil
        }

  def cast(ctx) do
    case cast_discriminator(ctx) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp cast_discriminator(%_{value: %{} = value, schema: schema, schemas: schemas} = ctx) do
    {discriminator_property, mappings} = discriminator_details(schema)

    case value["#{discriminator_property}"] || value[discriminator_property] do
      v when v in ["", nil] ->
        error(:no_value_for_discriminator, ctx)

      discriminator_value ->
        # The cast specified by the composite key (allOf, anyOf, oneOf) MUST succeed
        # or return an error according to the Open API Spec.
        composite_ctx = %{ctx | schema: %{schema | discriminator: nil}}

        cast_composition(composite_ctx, ctx, discriminator_value, mappings, schemas)
    end
  end

  defp cast_discriminator(ctx) do
    Cast.error(ctx, {:invalid_type, :object})
  end

  # When the composite key `allOf` is set we have to cast all the schemas even when the discriminator is set
  defp cast_composition(
         %_{schema: %{allOf: [_ | _]}} = composite_ctx,
         ctx,
         discriminator_value,
         mappings,
         schemas
       ) do
    with {composite_schemas, cast_composition_result} <-
           {locate_composition_schemas(composite_ctx), Cast.cast(composite_ctx)},
         {:ok, _} <- cast_composition_result,
         %{} = schema <-
           find_discriminator_schema(
             discriminator_value,
             mappings,
             composite_schemas,
             schemas
           ) do
      Cast.cast(%{composite_ctx | schema: schema})
    else
      nil -> error(:invalid_discriminator_value, ctx)
      {:error, _} = error -> error
    end
  end

  defp cast_composition(composite_ctx, ctx, discriminator_value, mappings, schemas) do
    with composite_schemas <- locate_composition_schemas(composite_ctx),
         %{} = schema <-
           find_discriminator_schema(discriminator_value, mappings, composite_schemas, schemas) do
      Cast.cast(%{composite_ctx | schema: schema})
    else
      nil -> error(:invalid_discriminator_value, ctx)
      {:error, _} = error -> error
    end
  end

  defp find_discriminator_schema(discriminator, mappings = %{}, composite_schemas, schemas) do
    case Map.fetch(mappings, discriminator) do
      {:ok, "#/components/schemas/" <> name} ->
        find_discriminator_schema(name, nil, composite_schemas, schemas) || Map.get(schemas, name)

      {:ok, name} ->
        find_discriminator_schema(name, nil, composite_schemas, schemas)

      :error ->
        find_discriminator_schema(discriminator, nil, composite_schemas, schemas)
    end
  end

  defp find_discriminator_schema(discriminator, nil, composite_schemas, _schemas)
       when is_atom(discriminator) and not is_nil(discriminator),
       do: Enum.find(composite_schemas, &Kernel.==(&1."x-struct", discriminator))

  defp find_discriminator_schema(discriminator, nil, composite_schemas, _schemas)
       when is_binary(discriminator),
       do: Enum.find(composite_schemas, &Kernel.==(&1.title, discriminator))

  defp find_discriminator_schema(_discriminator, _mappings, _composite_schemas, _schemas), do: nil

  defp discriminator_details(%{discriminator: %{propertyName: property_name, mapping: mappings}}),
    do: {String.to_existing_atom(property_name), mappings}

  defp error(message, %{schema: %{discriminator: %{propertyName: property}}} = ctx),
    do: Cast.error(ctx, {message, property})

  defp locate_composition_schemas(%_{schema: %{anyOf: [_ | _] = schemas}} = ctx),
    do: locate_schemas(schemas, ctx.schemas)

  defp locate_composition_schemas(%_{schema: %{allOf: [_ | _] = schemas}} = ctx),
    do: locate_schemas(schemas, ctx.schemas)

  defp locate_composition_schemas(%_{schema: %{oneOf: [_ | _] = schemas}} = ctx),
    do: locate_schemas(schemas, ctx.schemas)

  defp locate_schemas(schemas, ctx_schemas) do
    Enum.map(schemas, fn
      %Schema{} = schema ->
        schema

      %Reference{} = schema ->
        Reference.resolve_schema(schema, ctx_schemas)
    end)
  end
end
