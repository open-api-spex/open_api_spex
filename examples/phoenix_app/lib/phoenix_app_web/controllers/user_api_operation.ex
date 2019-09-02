defmodule PhoenixAppWeb.UserApiOperation do
  import OpenApiSpex.Operation, only: [parameter: 5, request_body: 4, response: 3]
  alias OpenApiSpex.Operation
  alias PhoenixAppWeb.Schemas

  @spec open_api_operation(atom) :: Operation.t()
  def open_api_operation(action) do
    operation = String.to_existing_atom("#{action}_operation")
    apply(__MODULE__, operation, [])
  end

  @doc """
  API Spec for :index action
  """
  def index_operation() do
    %Operation{
      tags: ["users"],
      summary: "List users",
      description: "List all useres",
      operationId: "UserController.index",
      responses: %{
        200 => response("User List Response", "application/json", Schemas.UsersResponse)
      }
    }
  end

  @doc """
  API Spec for :create action
  """
  def create_operation() do
    %Operation{
      tags: ["users"],
      summary: "Create user",
      description: "Create a user",
      operationId: "UserController.create",
      parameters: [
        Operation.parameter(:group_id, :path, :integer, "Group ID", example: 1)
      ],
      requestBody:
        request_body("The user attributes", "application/json", Schemas.UserRequest,
          required: true
        ),
      responses: %{
        201 => response("User", "application/json", Schemas.UserResponse)
      }
    }
  end

  @doc """
  API Spec for :show action
  """
  def show_operation() do
    %Operation{
      tags: ["users"],
      summary: "Show user",
      description: "Show a user by ID",
      operationId: "UserController.show",
      parameters: [
        parameter(:id, :path, :integer, "User ID", example: 123, minimum: 1, required: true)
      ],
      responses: %{
        200 => response("User", "application/json", Schemas.UserResponse)
      }
    }
  end
end
