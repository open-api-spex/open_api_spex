defmodule OpenApiSpexTest.Schemas do
  alias OpenApiSpex.Schema

  defmodule User do
    @derive [Poison.Encoder]
    @schema %Schema{
      title: "User",
      description: "A user of the app",
      type: :object,
      properties: %{
        id: %Schema{type: :integer, description: "User ID"},
        name:  %Schema{type: :string, description: "User name", pattern: ~r/[a-zA-Z][a-zA-Z0-9_]+/},
        email: %Schema{type: :string, description: "Email address", format: :email},
        inserted_at: %Schema{type: :string, description: "Creation timestamp", format: :'date-time'},
        updated_at: %Schema{type: :string, description: "Update timestamp", format: :'date-time'}
      },
      required: [:name, :email],
      example: %{
        "id" => 123,
        "name" => "Joe User",
        "email" => "joe@gmail.com",
        "inserted_at" => "2017-09-12T12:34:55Z",
        "updated_at" => "2017-09-13T10:11:12Z"
      },
      "x-struct": __MODULE__
    }
    def schema, do: @schema
    defstruct Map.keys(@schema.properties)

    @type t :: %__MODULE__{
      id: integer,
      name: String.t,
      email: String.t,
      inserted_at: DateTime.t,
      updated_at: DateTime.t
    }
  end

  defmodule UserRequest do
    @derive [Poison.Encoder]
    @schema %Schema{
      title: "UserRequest",
      description: "POST body for creating a user",
      type: :object,
      properties: %{
        user: User
      },
      example: %{
        "user" => %{
          "name" => "Joe User",
          "email" => "joe@gmail.com"
        }
      },
      "x-struct": __MODULE__
    }
    def schema, do: @schema
    defstruct Map.keys(@schema.properties)

    @type t :: %__MODULE__{
      user: User.t
    }
  end

  defmodule UserResponse do
    @derive [Poison.Encoder]
    @schema %Schema{
      title: "UserResponse",
      description: "Response schema for single user",
      type: :object,
      properties: %{
        data: User
      },
      example: %{
        "data" => %{
          "id" => 123,
          "name" => "Joe User",
          "email" => "joe@gmail.com",
          "inserted_at" => "2017-09-12T12:34:55Z",
          "updated_at" => "2017-09-13T10:11:12Z"
        }
      },
      "x-struct": __MODULE__
    }
    def schema, do: @schema
    defstruct Map.keys(@schema.properties)

    @type t :: %__MODULE__{
      data: User.t
    }
  end

  defmodule UsersResponse do
    @derive [Poison.Encoder]
    @schema %Schema{
      title: "UsersReponse",
      description: "Response schema for multiple users",
      type: :object,
      properties: %{
        data: %Schema{description: "The users details", type: :array, items: User}
      },
      example: %{
        "data" => [
          %{
            "id" => 123,
            "name" => "Joe User",
            "email" => "joe@gmail.com"
          },
          %{
            "id" => 456,
            "name" => "Jay Consumer",
            "email" => "jay@yahoo.com"
          }
        ]
      },
      "x-struct": __MODULE__
    }
    def schema, do: @schema
    defstruct Map.keys(@schema.properties)

    @type t :: %__MODULE__{
      data: [User.t]
    }
  end
end