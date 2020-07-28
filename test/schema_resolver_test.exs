defmodule OpenApiSpex.SchemaResolverTest do
  use ExUnit.Case, async: true

  alias OpenApiSpex.{
    Info,
    MediaType,
    OpenApi,
    Operation,
    Parameter,
    PathItem,
    Reference,
    RequestBody,
    Response,
    Schema
  }

  defmodule UserId do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      type: :string,
      description: "User ID",
      example: "user-123"
    })
  end

  test "schemas in requestBody are registered" do
    spec = %OpenApi{
      info: %Info{
        title: "Test",
        version: "1.0.0"
      },
      paths: %{
        "/api/users" => %PathItem{
          post: %Operation{
            description: "Create a user",
            operationId: "UserController.create",
            requestBody: %RequestBody{
              content: %{
                "application/json" => %MediaType{
                  schema: OpenApiSpexTest.Schemas.UserRequest
                }
              }
            },
            responses: %{}
          }
        }
      }
    }

    resolved = OpenApiSpex.resolve_schema_modules(spec)

    assert %Schema{} = resolved.components.schemas["UserRequest"]
    assert %Schema{} = resolved.components.schemas["User"]

    assert resolved.paths["/api/users"].post.requestBody.content["application/json"].schema ==
             %Reference{"$ref": "#/components/schemas/UserRequest"}
  end

  test "schemas in responses are registered" do
    spec = %OpenApi{
      info: %Info{
        title: "Test",
        version: "1.0.0"
      },
      paths: %{
        "/api/users" => %PathItem{
          get: %Operation{
            description: "Create a user",
            operationId: "UserController.create",
            responses: %{
              200 => %Response{
                description: "Success",
                content: %{
                  "application/json" => %MediaType{
                    schema: OpenApiSpexTest.Schemas.UsersResponse
                  }
                }
              }
            }
          }
        }
      }
    }

    resolved = OpenApiSpex.resolve_schema_modules(spec)

    assert %Schema{} = resolved.components.schemas["UsersResponse"]
    assert %Schema{} = resolved.components.schemas["User"]

    assert resolved.paths["/api/users"].get.responses[200].content["application/json"].schema ==
             %Reference{"$ref": "#/components/schemas/UsersResponse"}
  end

  test "schemas in parameters are registered" do
    spec = %OpenApi{
      info: %Info{
        title: "Test",
        version: "1.0.0"
      },
      paths: %{
        "/api/users" => %PathItem{
          get: %Operation{
            description: "Create a user",
            operationId: "UserController.create",
            parameters: [
              %Parameter{
                name: :id,
                in: :path,
                schema: UserId
              }
            ],
            responses: %{}
          }
        }
      }
    }

    resolved = OpenApiSpex.resolve_schema_modules(spec)

    titles = Map.keys(resolved.components.schemas)
    assert titles == ["UserId"]
    assert %Schema{} = resolved.components.schemas["UserId"]

    assert %Parameter{} = parameter = List.first(resolved.paths["/api/users"].get.parameters)
    assert parameter.name == :id
    assert parameter.schema == %Reference{"$ref": "#/components/schemas/UserId"}
  end

  test "paths with placeholders are not a problem" do
    spec = %OpenApi{
      info: %Info{
        title: "Test",
        version: "1.0.0"
      },
      paths: %{
        "/api/users/{id}/payment_details" => %PathItem{
          get: %Operation{
            responses: %{
              200 => %Response{
                description: "Success",
                content: %{
                  "application/json" => %MediaType{
                    schema: OpenApiSpexTest.Schemas.PaymentDetails
                  }
                }
              }
            }
          }
        }
      }
    }

    resolved = OpenApiSpex.resolve_schema_modules(spec)

    assert resolved.paths["/api/users/{id}/payment_details"].get.responses[200].content[
             "application/json"
           ].schema ==
             %Reference{"$ref": "#/components/schemas/PaymentDetails"}
  end

  test "response schemas do not need to be a module-based schema" do
    spec = %OpenApi{
      info: %Info{
        title: "Test",
        version: "1.0.0"
      },
      paths: %{
        "/api/users" => %PathItem{
          get: %Operation{
            responses: %{
              200 => %Response{
                description: "Success",
                content: %{
                  "application/json" => %MediaType{
                    schema: %Schema{
                      type: :array,
                      items: OpenApiSpexTest.Schemas.User
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    resolved = OpenApiSpex.resolve_schema_modules(spec)

    assert %Schema{} =
             schema =
             resolved.paths["/api/users"].get.responses[200].content["application/json"].schema

    assert schema.type == :array
    assert %Reference{"$ref": "#/components/schemas/User"} = schema.items
  end
end
