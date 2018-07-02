defmodule OpenApiSpexTest.PetController do
  use Phoenix.Controller

  alias OpenApiSpex.Operation
  alias OpenApiSpexTest.Schemas

  plug OpenApiSpex.Plug.Cast
  plug OpenApiSpex.Plug.Validate

  def open_api_operation(action) do
    apply(__MODULE__, :"#{action}_operation", [])
  end

  def index_operation() do
    import Operation

    %Operation{
      tags: ["pets"],
      summary: "List pets",
      description: "List all pets",
      operationId: "PetController.index",
      responses: %{
        200 => response("Pet List Response", "application/json", Schemas.PetsResponse)
      }
    }
  end
end
