defmodule OpenApiSpexTest.UserController do
  @moduledoc tags: ["users"]

  use Phoenix.Controller
  use OpenApiSpex.Controller

  alias OpenApiSpex.{Schema, Reference}
  alias OpenApiSpexTest.Schemas

  plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true

  @doc """
  Show user

  Show a user by ID
  """
  @doc parameters: [
         id: [
           in: :path,
           type: %Schema{type: :integer, minimum: 1},
           description: "User ID",
           example: 123
         ]
       ],
       responses: [
         ok: {"User", "application/json", Schemas.UserResponse}
       ]
  def show(conn, %{id: id}) do
    json(conn, %Schemas.UserResponse{
      data: %Schemas.User{
        id: id,
        name: "joe user",
        email: "joe@gmail.com"
      }
    })
  end

  @doc """
  List users

  List all users
  """
  @doc parameters: [
         validParam: [in: :query, type: :boolean, description: "Valid Param", example: true]
       ],
       responses: [
         ok: {"User List Response", "application/json", Schemas.UsersResponse}
       ]
  def index(conn, _params) do
    json(conn, %Schemas.UsersResponse{
      data: [
        %Schemas.User{
          id: 123,
          name: "joe user",
          email: "joe@gmail.com"
        }
      ]
    })
  end

  @doc """
  Create user.

  Create a user.
  """
  @doc request_body: {"The user attributes", "application/json", Schemas.UserRequest},
       responses: [
         created: {"User", "application/json", Schemas.UserResponse}
       ]
  def create(conn = %{body_params: %Schemas.UserRequest{user: user = %Schemas.User{}}}, _) do
    json(conn, %Schemas.UserResponse{
      data: %{user | id: 1234}
    })
  end

  @doc """
  Update contact info

  Update contact info
  """
  @doc parameters: [
         id: [in: :path, type: :integer, description: "user ID"]
       ],
       request_body: {"Contact info", "application/json", Schemas.ContactInfo},
       responses: [
         # TODO allow specifyng no respond body
         no_content: "OK"
       ]
  def contact_info(conn = %{body_params: %Schemas.ContactInfo{}}, %{id: id}) do
    conn
    |> put_status(200)
    |> json(%{id: id})
  end

  @doc """
  Show user payment details.

  Shows a users payment details.
  """
  @doc parameters: [
         %Reference{"$ref": "#/components/parameters/id"}
       ],
       responses: [
         ok: {"Payment Details", "application/json", Schemas.PaymentDetails}
       ]
  def payment_details(conn, %{id: id}) do
    response =
      case rem(id, 2) do
        0 ->
          %Schemas.CreditCardPaymentDetails{
            credit_card_number: "1234-5678-0987-6543",
            name_on_card: "Joe User",
            expiry: "0522"
          }

        1 ->
          %Schemas.DirectDebitPaymentDetails{
            account_number: "98776543",
            account_name: "Joes Savings",
            bsb: "123-567"
          }
      end

    json(conn, response)
  end

  @doc """
  Create an EntityWithDict

  Create an EntityWithDict
  """
  @doc tags: ["EntityWithDict"],
       request_body: {"Entity attributes", "application/json", Schemas.EntityWithDict},
       responses: [
         created: {"EntityWithDict", "application/json", Schemas.EntityWithDict}
       ]
  def create_entity(conn, %Schemas.EntityWithDict{} = entity) do
    json(conn, Map.put(entity, :id, 123))
  end
end
