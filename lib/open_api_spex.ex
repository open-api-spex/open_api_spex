defmodule OpenApiSpex do
  alias OpenApiSpex.{OpenApi, SchemaResolver}

  @moduledoc """
  """
  def resolve_schema_modules(spec = %OpenApi{}) do
    SchemaResolver.resolve_schema_modules(spec)
  end


end
