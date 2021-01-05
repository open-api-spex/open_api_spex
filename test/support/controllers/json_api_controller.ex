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
  @doc parameters: [
         page: [in: :query, type: JsonApiSchemas.PageBasedPaginationParameter, required: true]
       ],
       responses: [
         ok: {
           "Carts",
           "application/json",
           JsonApiSchemas.CartPaginatedDocument
         }
       ]
  def paginated_index(conn, %{page: page}) do
    page_params = Map.from_struct(page)
    uri = %URI{scheme: "https", host: "example.com"}

    paged_url_fn =
      &OpenApiSpexTest.Router.Helpers.json_api_url(uri, :paginated_index,
        page: %{page_params | number: &1}
      )

    response = %{
      data: [],
      links: %{
        first: paged_url_fn.(1),
        last: paged_url_fn.(10),
        prev: paged_url_fn.(page.number - 1),
        next: paged_url_fn.(page.number + 1)
      }
    }

    json(conn, response)
  end

  @spec annotated_index(Plug.Conn.t(), any) :: Plug.Conn.t()
  @doc """
  Get a list of carts, but defined in annotation.
  """
  @doc responses: [
         ok: {
           "Carts",
           "application/json",
           JsonApiHelpers.document_schema(
             title: "CartAnnotatedDocument",
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
  @doc request_body: {"CartDocument", "application/json", @resource_document},
       responses: [
         created: {"CartDocument", "application/json", @resource_document}
       ]
  def create(%Plug.Conn{body_params: payload} = conn, _params) do
    response = %{
      data: %JsonApiSchemas.CartResource{
        id: "492e7435-cd23-4ce0-a189-edf7fdc4b490",
        type: "cart",
        attributes: payload.data.attributes
      }
    }

    conn
    |> put_status(:created)
    |> json(response)
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
