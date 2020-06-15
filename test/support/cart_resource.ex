defmodule OpenApiSpexTest.CartResource do
  alias OpenApiSpex.JsonApiHelpers.JsonApiResource
  alias OpenApiSpex.Schema

  @resource %JsonApiResource{
    title: "Cart",
    properties: %{
      total: %Schema{type: :integer}
    },
    additionalProperties: false
  }

  def resource, do: @resource
end
