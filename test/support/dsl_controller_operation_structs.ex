defmodule OpenApiSpexTest.DslControllerOperationStructs do
  use Phoenix.Controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Operation

  alias OpenApiSpexTest.DslController

  tags ["users"]

  security [%{"api_key" => ["mySecurityScheme"]}]

  operation :update,
    summary: "Update user",
    parameters: [
      Operation.parameter(:id, :path, :integer, "User ID", example: 1001)
    ],
    request_body:
      Operation.request_body(
        "User params",
        %{
          "application/json" => [example: "json example request"],
          "application/text" => [example: "text example request"]
        },
        DslController.UserParams
      ),
    responses: [
      ok:
        Operation.response(
          "User response",
          %{
            "application/json" => [example: "json example response"],
            "application/text" => [example: "text example response"]
          },
          DslController.UserResponse,
          headers: %{
            "content-type" => %OpenApiSpex.Header{
              description: "Type of the content for the response",
              example: "content-type: application/json; charset=utf-8"
            }
          }
        )
    ],
    tags: ["custom"],
    security: [%{"two" => ["another"]}]

  def update(conn, %{"id" => id}) do
    conn
    |> put_resp_header("content-type", "application/json; charset=utf-8")
    |> json(%{
      data: %{
        id: id,
        name: "joe user",
        email: "joe@gmail.com"
      }
    })
  end
end
