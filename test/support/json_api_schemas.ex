defmodule OpenApiSpexTest.JsonApiSchemas do
  alias OpenApiSpex.JsonApiHelpers
  alias OpenApiSpex.Schema
  alias OpenApiSpex.JsonApiHelpers.JsonApiDocument
  alias OpenApiSpex.JsonApiHelpers.JsonApiResource

  require OpenApiSpex.JsonApiHelpers

  defmodule CartResource do
    JsonApiHelpers.generate_resource_schema(
      title: "Cart",
      properties: %{
        total: %Schema{type: :integer}
      },
      additionalProperties: false
    )
  end

  defmodule PageBasedPaginationParameter do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "PageBasedPaginationParameter",
      type: :object,
      properties: %{
        number: %Schema{type: :integer},
        size: %Schema{type: :integer}
      }
    })
  end

  defmodule CartDocument do
    JsonApiHelpers.generate_document_schema(
      title: "CartDocument",
      resource: CartResource
    )
  end

  defmodule CartListDocument do
    JsonApiHelpers.generate_document_schema(
      title: "CartListDocument",
      paginated: true,
      resource: CartResource
    )
  end

  defmodule CartPaginatedDocument do
    JsonApiHelpers.generate_document_schema(
      title: "CartPaginatedDocument",
      paginated: true,
      resource: CartResource
    )
  end
end
