defmodule OpenApiSpexTest.PetController do
  use Phoenix.Controller
  alias OpenApiSpex.Operation
  alias OpenApiSpexTest.Schemas

  plug OpenApiSpex.Plug.CastAndValidate

  def open_api_operation(action) do
    apply(__MODULE__, :"#{action}_operation", [])
  end

  @doc """
  API Spec for :show action
  """
  def show_operation() do
    import Operation

    %Operation{
      tags: ["pets"],
      summary: "Show pet",
      description: "Show a pet by ID",
      operationId: "PetController.show",
      parameters: [
        parameter(:id, :path, :integer, "Pet ID", example: 123, minimum: 1)
      ],
      responses: %{
        200 => response("Pet", "application/json", Schemas.PetResponse)
      }
    }
  end

  def show(conn, %{id: _id}) do
    json(conn, %Schemas.PetResponse{
      data: %Schemas.Dog{
        pet_type: "Dog",
        bark: "woof"
      }
    })
  end

  def index_operation() do
    import Operation

    %Operation{
      tags: ["pets"],
      summary: "List pets",
      description: "List all petes",
      operationId: "PetController.index",
      parameters: [
        parameter(:validParam, :query, :boolean, "Valid Param", example: true)
      ],
      responses: %{
        200 => response("Pet List Response", "application/json", Schemas.PetsResponse)
      }
    }
  end

  def index(conn, _params) do
    json(conn, %Schemas.PetsResponse{
      data: [
        %Schemas.Dog{
          pet_type: "Dog",
          bark: "joe@gmail.com"
        }
      ]
    })
  end

  def create_operation() do
    import Operation

    %Operation{
      tags: ["pets"],
      summary: "Create pet",
      description: "Create a pet",
      operationId: "PetController.create",
      parameters: [],
      requestBody: request_body("The pet attributes", "application/json", Schemas.PetRequest),
      responses: %{
        201 => response("Pet", "application/json", Schemas.PetRequest)
      }
    }
  end

  def create(conn = %{body_params: %Schemas.PetRequest{pet: pet}}, _) do
    json(conn, %Schemas.PetResponse{
      data: pet
    })
  end

  def adopt_operation() do
    import Operation

    %Operation{
      tags: ["pets"],
      summary: "Adopt pet",
      description: "Adopt a pet",
      operationId: "PetController.adopt",
      parameters: [
        parameter(
          "x-user-id",
          :header,
          :string,
          "User that performs this action",
          required: true
        ),
        parameter(:id, :path, :integer, "Pet ID", example: 123, minimum: 1)
      ],
      responses: %{
        200 => response("Pet", "application/json", Schemas.PetRequest)
      }
    }
  end

  def adopt(conn, _) do
    json(conn, %Schemas.PetResponse{
      data: %Schemas.Dog{
        pet_type: "Dog",
        bark: "woof"
      }
    })
  end
end
