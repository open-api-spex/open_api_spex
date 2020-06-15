defmodule OpenApiSpexTest.CartDocument do
  alias OpenApiSpex.JsonApiHelpers
  alias OpenApiSpex.JsonApiHelpers.JsonApiResource
  alias OpenApiSpex.Schema

  require OpenApiSpex.JsonApiHelpers

  JsonApiHelpers.generate_document_schema(
    title: "Cart",
    resource: %JsonApiResource{
      properties: %{
        total: %Schema{type: :integer}
      },
      additionalProperties: false
    }
  )
end
