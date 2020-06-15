defmodule OpenApiSpexTest.JsonApiController do
  use Phoenix.Controller
  use OpenApiSpex.Controller

  alias OpenApiSpex.JsonApiHelpers
  alias OpenApiSpexTest.CartResource

  @doc """
  Get a list of carts.
  """
  @doc responses: [
         ok: {
           "Carts",
           "application/json",
           OpenApiSpexTest.CartIndexDocument
           #  JsonApiHelpers.document_schema(
           #    title: "Carts",
           #    resource: CartResource.resource(),
           #    multiple: true
           #  )
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
