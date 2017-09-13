defmodule OpenApiSpexTest.Schemas do
  alias OpenApiSpex.Schema

  defmodule User do
    def schema do
      %Schema{
        title: "User",
        description: "A user of the app",
        type: :object,
        properties: %{
          id: %Schema{type: :integer, description: "User ID"},
          name:  %Schema{type: :string, description: "User name"},
          email: %Schema{type: :string, description: "Email address", format: :email},
          inserted_at: %Schema{type: :string, description: "Creation timestamp", format: :datetime},
          updated_at: %Schema{type: :string, description: "Update timestamp", format: :datetime}
        }
      }
    end
  end

  defmodule UserRequest do
    def schema do
      %Schema{
        title: "UserRequest",
        description: "POST body for creating a user",
        type: :object,
        properties: %{
          user: User
        }
      }
    end
  end

  defmodule UserResponse do
    def schema do
      %Schema{
        title: "UserResponse",
        description: "Response schema for single user",
        type: :object,
        properties: %{
          data: User
        }
      }
    end
  end

  defmodule UsersResponse do
    def schema do
      %Schema{
        title: "UsersReponse",
        description: "Response schema for multiple users",
        type: :object,
        properties: %{
          data: %Schema{description: "The users details", type: :array, items: User}
        }
      }
    end
  end
end