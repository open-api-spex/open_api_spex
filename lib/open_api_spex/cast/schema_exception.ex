defmodule OpenApiSpex.SchemaException do
  defexception [:message]
  @impl true
  def exception(%{error: :discriminator_schema_missing_title, schema: schema, details: details}) do
    identifier = schema.title || schema.type
    discriminator = details[:property_name]

    details =
      "Invalid Schema for discriminator, schema must have a title. " <>
        "Discriminator propertyName: " <> discriminator <> "schema: " <> inspect(schema)

    exception(%{identifier: identifier, details: details})
  end

  def exception(%{error: :discriminator_missing_composite_key, schema: schema}) do
    identifier = schema.title || schema.type
    details = "Discriminators require a composite key (`allOf`, `anyOf`, `oneOf`) be set."

    exception(%{identifier: identifier, details: details})
  end

  def exception(%{identifier: identifier, details: details}) do
    message = "Fatal! Improperly defined schema `#{identifier}`.\n\tDetails: #{details}\n"

    %__MODULE__{message: message}
  end

  def exception(value) do
    "Error Resolving Schema, details: #{inspect(value)}"
  end
end
