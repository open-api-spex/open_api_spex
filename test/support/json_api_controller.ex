defmodule OpenApiSpexTest.JsonApiController do
  use Phoenix.Controller
  use OpenApiSpex.Controller

  alias OpenApiSpex.JsonApiHelpers
  alias OpenApiSpexTest.CartResource

  require OpenApiSpex.JsonApiHelpers

  @doc """
  Get a list of carts.
  """
  @doc responses: [
         ok: {
           "Carts",
           "application/json",
           JsonApiHelpers.document_schema(
             title: "CartIndexResponse",
             resource: CartResource,
             multiple: true,
             "x-struct": "CartIndexResponse"
           )
         }
       ]
  def index(conn, _params) do
    json(conn, %{data: []})
  end

  @doc """
  Get a cart by ID.
  """
  @doc responses: [
         ok: {
           "Cart",
           "application/json",
           JsonApiHelpers.document_schema(
             title: "Cart",
             resource: CartResource.resource()
           )
         }
       ]
  def show(conn, _params) do
    json(conn, %{data: %{}})
  end
end
