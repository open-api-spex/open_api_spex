defmodule OpenApiSpexTest.Tasks.SpecModule do
  alias OpenApiSpex.{Info, OpenApi, Operation, Server}

  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      info: %Info{
        title: "Test spec",
        version: "1.0"
      },
      paths: %{
        "/users" => %{
          "post" => %Operation{operationId: "users.create", responses: %{}},
          "put" => %Operation{operationId: "users.update", responses: %{}}
        }
      },
      servers: [
        %Server{url: "http://localhost:4000"}
      ]
    }
  end
end
