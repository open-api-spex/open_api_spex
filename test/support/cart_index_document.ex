defmodule OpenApiSpexTest.CartIndexDocument do
  alias OpenApiSpex.JsonApiHelpers
  alias OpenApiSpexTest.CartResource

  require OpenApiSpex.JsonApiHelpers

  JsonApiHelpers.generate_document_schema(
    title: "CartIndexDocument",
    multiple: true,
    resource: CartResource
  )
end
