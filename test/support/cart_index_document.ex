defmodule OpenApiSpexTest.CartIndexDocument do
  alias OpenApiSpex.JsonApiHelpers
  alias OpenApiSpexTest.CartResource

  require OpenApiSpex.JsonApiHelpers

  JsonApiHelpers.generate_document_schema(
    title: "CartIndex",
    multiple: true,
    resource: CartResource.resource()
  )
end
