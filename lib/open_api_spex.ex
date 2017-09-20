defmodule OpenApiSpex do
  alias OpenApiSpex.{OpenApi, Operation, Reference, Schema, SchemaResolver}

  @moduledoc """
  """
  def resolve_schema_modules(spec = %OpenApi{}) do
    SchemaResolver.resolve_schema_modules(spec)
  end

  @doc """
  Cast params to conform to a Schema or Operation spec.
  """
  def cast(spec = %OpenApi{}, schema = %Schema{}, params) do
    Schema.cast(schema, params, spec.compnents.schemas)
  end
  def cast(spec = %OpenApi{}, schema = %Reference{}, params) do
    Schema.cast(schema, params, spec.compnents.schemas)
  end
  def cast(spec = %OpenApi{}, operation = %Operation{}, params, content_type \\ nil) do
    Operation.cast(operation, params, content_type, spec.components.schemas)
  end


  @doc """
  Validate params against a Schema or Operation spec.
  """
  def validate(spec = %OpenApi{}, schema = %Schema{}, params) do
    Schema.validate(schema, params, spec.components.schemas)
  end
  def validate(spec = %OpenApi{}, schema = %Reference{}, params) do
    Schema.validate(schema, params, spec.components.schemas)
  end
  def validate(spec = %OpenApi{}, operation = %Operation{}, params = %{}, content_type \\ nil) do
    Operation.validate(operation, params, content_type, spec.components.schemas)
  end
end
