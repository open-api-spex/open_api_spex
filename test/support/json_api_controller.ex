defmodule OpenApiSpexTest.JsonApiController do
  use Phoenix.Controller
  use OpenApiSpex.Controller

  alias OpenApiSpex.JsonApiHelpers

  alias OpenApiSpexTest.JsonApiSchemas

  require OpenApiSpex.JsonApiHelpers

  plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true

  @resource JsonApiSchemas.CartResource
  @resource_document JsonApiSchemas.CartDocument

  @doc """
  Get a list of carts.
  """
  @doc responses: [
         ok: {
           "Carts",
           "application/json",
           JsonApiSchemas.CartListDocument
         }
       ]
  def index(conn, _params) do
    json(conn, %{data: []})
  end

  @doc """
  Get a list of carts, but paginated.
  """
  @doc responses: [
         ok: {
           "Carts",
           "application/json",
           JsonApiHelpers.document_schema(
             title: "CartIndexResponse",
             resource: @resource,
             multiple: true
           )
         }
       ]
  def paged_index(conn, _params) do
    json(conn, %{data: []})
  end

  @doc """
  Get a list of carts, but defined in annotation.
  """
  @doc responses: [
         ok: {
           "Carts",
           "application/json",
           JsonApiHelpers.document_schema(
             title: "CartIndexResponse",
             resource: @resource,
             multiple: true
           )
         }
       ]
  def annotated_index(conn, _params) do
    json(conn, %{data: []})
  end

  @doc """
  Create a Cart.
  """
  @doc
  @doc request_body: {"CartDocument", "application/json", @resource_document},
       responses: [
         created: {"CartDocument", "application/json", @resource_document}
       ]
  def create(conn, _params) do
    json(conn, %@resource_document{data: %@resource{}})
  end

  @doc """
  Get a cart by ID.
  """
  @doc responses: [
         ok: {
           "Cart",
           "application/json",
           @resource_document
         }
       ]
  def show(conn, _params) do
    json(conn, %{data: %{}})
  end

  @doc """
  Updating a Cart's Attributes

  This action is available as a PUT or a PATCH.
  """
  @doc request_body:
         {"The cart attributes", "application/json", @resource_document, required: true},
       responses: [
         created: {"Car", "application/json", @resource_document}
       ]
  def update(conn, _) do
    json(conn, %@resource_document{
      data: %@resource{
        id: "123",
        type: "cart",
        attributes: %{
          total: "4000"
        }
      }
    })
  end
end
