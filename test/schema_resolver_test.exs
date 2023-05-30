defmodule OpenApiSpex.SchemaResolverTest do
  use ExUnit.Case

  alias OpenApiSpex.{
    Info,
    MediaType,
    OpenApi,
    Operation,
    PathItem,
    Reference,
    RequestBody,
    Response,
    Schema,
    SchemaResolver
  }

  test "Resolves schemas in OpenApi spec" do
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
                    schema: OpenApiSpexTest.Schemas.UsersResponse
                  }
                }
              }
            }
          },
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
            responses: %{
              201 => %Response{
                description: "Created",
                content: %{
                  "application/json" => %MediaType{
                    schema: OpenApiSpexTest.Schemas.UserResponse
                  }
                }
              }
            }
          }
        },
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
        },
        "/api/users/{id}/friends" => %PathItem{
          get: %Operation{
            parameters: [
              %OpenApiSpex.Parameter{
                name: :id,
                in: :path,
                schema: %Schema{type: :integer}
              }
            ],
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
        },
        "/api/users/subscribe" => %PathItem{
          post: %Operation{
            description: "Subscribe to user updates",
            operationId: "UserController.subscribe",
            requestBody: %RequestBody{
              required: true,
              content: %{
                "application/json" => %MediaType{
                  schema: OpenApiSpexTest.Schemas.UserSubscribeRequest
                }
              }
            },
            callbacks: %{
              "user_updated" => %{
                "{$request.body#/callback_url}" => %PathItem{
                  post: %Operation{
                    description: "Provided endpoint for sending updates",
                    requestBody: %RequestBody{
                      required: true,
                      content: %{
                        "application/json" => %MediaType{
                          schema: OpenApiSpexTest.Schemas.UserResponse
                        }
                      }
                    },
                    responses: %{
                      200 => %Response{
                        description: "Your server returns this code if it accepts the callback"
                      }
                    }
                  }
                }
              }
            },
            responses: %{
              201 => %Response{
                description: "Webhook created"
              }
            }
          }
        },
        "/api/appointsments" => %PathItem{
          post: %Operation{
            description: "Create a new pet appointment",
            operationId: "PetAppointmentController.create",
            requestBody: %RequestBody{
              required: true,
              content: %{
                "application/json" => %MediaType{
                  schema: OpenApiSpexTest.Schemas.PetAppointmentRequest
                }
              }
            },
            responses: %{
              201 => %Response{
                description: "Appointment created"
              }
            }
          }
        }
      }
    }

    resolved = OpenApiSpex.resolve_schema_modules(spec)

    assert %Reference{"$ref": "#/components/schemas/UsersResponse"} =
             resolved.paths["/api/users"].get.responses[200].content["application/json"].schema

    assert %Reference{"$ref": "#/components/schemas/UserResponse"} =
             resolved.paths["/api/users"].post.responses[201].content["application/json"].schema

    assert %Reference{"$ref": "#/components/schemas/UserRequest"} =
             resolved.paths["/api/users"].post.requestBody.content["application/json"].schema

    assert "#/components/schemas/TrainingAppointment" =
             resolved.components.schemas["PetAppointmentRequest"].discriminator.mapping[
               "training"
             ]

    assert "#/components/schemas/GroomingAppointment" =
             resolved.components.schemas["PetAppointmentRequest"].discriminator.mapping[
               "grooming"
             ]

    assert %{
             "UserRequest" => %Schema{},
             "UserResponse" => %Schema{},
             "User" => %Schema{},
             "UserSubscribeRequest" => %Schema{},
             "PaymentDetails" => %Schema{},
             "CreditCardPaymentDetails" => %Schema{},
             "DirectDebitPaymentDetails" => %Schema{},
             "PetAppointmentRequest" => %Schema{},
             "TrainingAppointment" => %Schema{},
             "GroomingAppointment" => %Schema{}
           } = resolved.components.schemas

    get_friends = resolved.paths["/api/users/{id}/friends"].get

    assert %Reference{"$ref": "#/components/schemas/User"} =
             get_friends.responses[200].content["application/json"].schema.items
  end

  test "raises informative error when schema :properties is not a map" do
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
                      type: :object,
                      properties: Invalid
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    assert_raise RuntimeError, "Expected :properties to be a map. Got: Invalid", fn ->
      OpenApiSpex.resolve_schema_modules(spec)
    end
  end

  test "raises error when schema cannot be resolved" do
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
                    schema: %{}
                  }
                }
              }
            }
          }
        }
      }
    }

    error_message = """
    Cannot resolve schema %{}.

    Must be one of:

    - schema module, or schema struct
    - list of schema modules, or schema structs
    - boolean
    - nil
    - reference
    """

    assert_raise RuntimeError, error_message, fn ->
      OpenApiSpex.resolve_schema_modules(spec)
    end
  end

  describe "add_schemas/2" do
    @empty_spec %OpenApi{
      info: %Info{
        title: "Test",
        version: "1.0.0"
      },
      paths: %{},
      components: %{schemas: %{}}
    }

    defmodule SomeSchema do
      def schema do
        %Schema{
          type: :object,
          title: "SomeSchema",
          properties: %{name: %Schema{type: :string}}
        }
      end
    end

    test "Schema module" do
      spec = SchemaResolver.add_schemas(@empty_spec, [SomeSchema])

      assert spec.components.schemas == %{
               "SomeSchema" => SomeSchema.schema()
             }
    end

    defmodule ArraySchema do
      def schema do
        %Schema{
          type: :type,
          title: "ArraySchema",
          items: SomeSchema
        }
      end
    end

    test "Schema module of type:array with module-referenced items" do
      spec = SchemaResolver.add_schemas(@empty_spec, [ArraySchema])

      assert %{
               "ArraySchema" => array_schema,
               "SomeSchema" => some_schema
             } = spec.components.schemas

      assert some_schema == SomeSchema.schema()
      assert array_schema.title == "ArraySchema"

      assert array_schema.items == %OpenApiSpex.Reference{
               "$ref": "#/components/schemas/SomeSchema"
             }
    end
  end
end
