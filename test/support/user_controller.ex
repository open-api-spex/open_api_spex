defmodule OpenApiSpexTest.UserController do
  use Phoenix.Controller
  alias OpenApiSpex.Operation
  alias OpenApiSpexTest.Schemas

  plug OpenApiSpex.Plug.Cast
  plug OpenApiSpex.Plug.Validate

  def open_api_operation(action) do
    apply(__MODULE__, :"#{action}_operation", [])
  end

  @doc """
  API Spec for :show action
  """
  def show_operation() do
    import Operation
    %Operation{
      tags: ["users"],
      summary: "Show user",
      description: "Show a user by ID",
      operationId: "UserController.show",
      parameters: [
        parameter(:id, :path, :integer, "User ID", example: 123, minimum: 1)
      ],
      responses: %{
        200 => response("User", "application/json", Schemas.UserResponse)
      }
    }
  end
  def show(conn, %{id: id}) do
    json(conn, %Schemas.UserResponse{
      data: %Schemas.User{
        id: id,
        name: "joe user",
        email: "joe@gmail.com"
      }
    })
  end

  def index_operation() do
    import Operation
    %Operation{
      tags: ["users"],
      summary: "List users",
      description: "List all useres",
      operationId: "UserController.index",
      parameters: [
        parameter(:validParam, :query, :boolean, "Valid Param", example: true)
      ],
      responses: %{
        200 => response("User List Response", "application/json", Schemas.UsersResponse)
      }
    }
  end
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

  def create_operation() do
    import Operation
    %Operation{
      tags: ["users"],
      summary: "Create user",
      description: "Create a user",
      operationId: "UserController.create",
      parameters: [],
      requestBody: request_body("The user attributes", "application/json", Schemas.UserRequest),
      responses: %{
        201 => response("User", "application/json", Schemas.UserResponse)
      }
    }
  end
  def create(conn = %{body_params: %Schemas.UserRequest{user: user = %Schemas.User{}}}, _) do
    json(conn, %Schemas.UserResponse{
      data: %{user | id: 1234}
    })
  end

  def contact_info_operation() do
    import Operation
    %Operation{
      tags: ["users"],
      summary: "Update contact info",
      description: "Update contact info",
      operationId: "UserController.contact_info",
      parameters: [
        parameter(:id, :path, :integer, "user ID")
      ],
      requestBody: request_body("Contact info", "application/json", Schemas.ContactInfo),
      responses: %{
        200 => %OpenApiSpex.Response{
          description: "OK"
        }
      }
    }
  end
  def contact_info(conn = %{body_params: %Schemas.ContactInfo{}}, %{id: id}) do
    conn
    |> put_status(200)
    |> json(%{id: id})
  end

  def payment_details_operation() do
    import Operation
    %Operation{
      tags: ["users"],
      summary: "Show user payment details",
      description: "Shows a users payment details",
      operationId: "UserController.payment_details",
      parameters: [
        parameter(:id, :path, :integer, "User ID", example: 123, minimum: 1)
      ],
      responses: %{
        200 => response("Payment Details", "application/json", Schemas.PaymentDetails)
      }
    }
  end
  def payment_details(conn, %{"id" => id}) do
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

  def create_entity_operation() do
    import Operation
    %Operation{
      tags: ["EntityWithDict"],
      summary: "Create an EntityWithDict",
      description: "Create an EntityWithDict",
      operationId: "UserController.create_entity",
      parameters: [],
      requestBody: request_body("Entity attributes", "application/json", Schemas.EntityWithDict),
      responses: %{
        201 => response("EntityWithDict", "application/json", Schemas.EntityWithDict)
      }
    }
  end
  def create_entity(conn, %Schemas.EntityWithDict{} = entity) do
    json(conn, Map.put(entity, :id, 123))
  end
end
