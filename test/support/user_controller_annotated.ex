defmodule OpenApiSpexTest.UserControllerAnnotated do
  @moduledoc tags: ["User"]

  use OpenApiSpex.Controller
  alias OpenApiSpex.{Header, Reference}
  alias OpenApiSpexTest.Schemas.{GenericError, NotFound, Unauthorized, User}

  @doc """
  Update a user

  Full description for this endpoint...
  """
  @doc external_docs: %{
         description: "Check out these docs",
         url: "https://example.com/"
       }
  @doc parameters: [
         id: [in: :path, type: :string, required: true]
       ]
  @doc request_body: {"Request body to update a User", "application/json", User, required: true}
  @doc responses: [
         ok: {
           "User response",
           "application/json",
           User,
           headers: %{"token" => %Header{description: "Access token"}}
         },
         unauthorized: Unauthorized.response(),
         not_found: NotFound.response(),
         unprocessable_entity: %Reference{"$ref": "#/components/responses/unprocessable_entity"},
         default: GenericError.response()
       ]
  @doc security: [%{"authorization" => []}]
  def update(_conn, _params), do: :ok

  @doc """
  Show a user

  Fuller description for this endpoint...
  """
  @doc operation_id: "show_user"
  @doc parameters: [
         "$ref": "#/components/parameters/id"
       ]
  @doc responses: [
         ok: {"User response", "application/json", User}
       ]
  def show(_conn, _params), do: :ok

  @doc responses: [ok: "Empty"]
  def minimal_docs(_conn, _params), do: :ok

  @doc false
  def skip_this_doc(_conn, _params), do: :ok

  def no_doc_specified(_conn, _params), do: :ok

  @doc parameters: [
         id: [in: :path, type: :string, required: true]
       ],
       responses: [ok: "Empty"]
  def only_schema_parameter_present_docs(_conn, _params), do: :ok

  @doc parameters: [
         id: [in: :path, type: :string, required: true]
       ],
       responses: [ok: "Empty"]
  def only_type_parameter_present_docs(_conn, _params), do: :ok

  @doc parameters: [
         id: [
           in: :path,
           type: :string,
           schema: %OpenApiSpex.Schema{type: :string, format: :date},
           required: true
         ]
       ],
       responses: [ok: "Empty"]
  def non_exlusive_paramter_type_schema_docs(_conn, _params), do: :ok
end
