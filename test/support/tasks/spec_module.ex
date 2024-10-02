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
      ],
      components: %{
        schemas: %{
          "Person" => %OpenApiSpex.Schema{
            type: :object,
            properties: %{
              first_name: %OpenApiSpex.Schema{type: :string},
              last_name: %OpenApiSpex.Schema{type: :string},
              nickname: %OpenApiSpex.Schema{type: :string, nullable: true}
            },
            required: [:first_name, :last_name, :nickname],
            example: %{
              first_name: "John",
              last_name: "Doe",
              nickname: nil
            }
          }
        }
      }
    }
  end
end
