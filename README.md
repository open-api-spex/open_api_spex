# Open API Spex [![Build Status](https://travis-ci.org/mbuhot/open_api_spex.svg?branch=master)](https://travis-ci.org/mbuhot/open_api_spex)

Add Open API Specification 3 (formerly swagger) to Plug applications.

## Installation

The package can be installed by adding `open_api_spex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:open_api_spex, github: "mbuhot/open_api_spex"}
  ]
end
```

## Generating an API spec

Start by adding an `ApiSpec` module to your application.

```elixir
defmodule MyApp.ApiSpec do
  alias OpenApiSpex.{OpenApi, Server, Info, Paths}

  def spec do
    %OpenApi{
      servers: [
        # Populate the Server info from a phoenix endpoint
        Server.from_endpoint(MyAppWeb.Endpoint, otp_app: :my_app)
      ],
      info: %Info{
        title: "My App",
        version: "1.0"
      },
      # populate the paths from a phoenix router
      paths: Paths.from_router(MyAppWeb.Router)
    }
    |> OpenApiSpex.resolve_schema_modules() # discover request/response schemas from path specs
  end
end
```

For each plug (controller) that will handle api requests, add an `open_api_operation` callback.
It will be passed the plug opts that were declared in the router, this will be the action for a phoenix controller.

```elixir
defmodule MyApp.UserController do
  alias OpenApiSpex.Operation
  alias MyApp.Schemas.UserResponse

  @spec open_api_operation(any) :: Operation.t
  def open_api_operation(action), do: apply(__MODULE__, :"#{action}_operation", [])

  @spec show_operation() :: Operation.t
  def show_operation() do

    %Operation{
      tags: ["users"],
      summary: "Show user",
      description: "Show a user by ID",
      operationId: "UserController.show",
      parameters: [
        Operation.parameter(:id, :path, :integer, "User ID", example: 123)
      ],
      responses: %{
        200 => Operation.response("User", "application/json", UserResponse)
      }
    }
  end
  def show(conn, %{"id" => id}) do
    {:ok, user} = MyApp.Users.find_by_id(id)
    json(conn, 200, user)
  end
end
```

Declare the JSON schemas for request/response bodies in a `Schemas` module:
Each module should export a `schema/0` function, and may optionally declare a struct,
linked to the JSON schema through the `x-struct` extension property.

```elixir
defmodule MyApp.Schemas do
  alias OpenApiSpex.Schema

  defmodule User do
    @derive [Poison.Encoder]
    @schema %Schema{
      title: "User",
      description: "A user of the app",
      type: :object,
      properties: %{
        id: %Schema{type: :integer, description: "User ID"},
        name:  %Schema{type: :string, description: "User name"},
        email: %Schema{type: :string, description: "Email address", format: :email},
        inserted_at: %Schema{type: :string, description: "Creation timestamp", format: :datetime},
        updated_at: %Schema{type: :string, description: "Update timestamp", format: :datetime}
      },
      required: [:name, :email],
      example: {
        "id" => 123,
        "name" => "Joe",
        "email" => "joe@gmail.com"
      }
      "x-struct": __MODULE__
    }
    def schema, do: @schema
    defstruct Map.keys(@schema.properties)
  end

  defmodule UserResponse do
    @schema %Schema{
      title: "UserResponse",
      description: "Response schema for single user",
      type: :object,
      properties: %{
        data: User
      },
      "x-struct": __MODULE__
    }
    def schema, do: @schema
    defstruct Map.keys(@schema.properties)
  end
end
```

Now you can create a mix task to write the swagger file to disk:

```elixir
defmodule Mix.Tasks.MyApp.OpenApiSpec do
  def run([output_file]) do
    json =
      MyApp.ApiSpec.spec()
      |> Poison.encode!(pretty: true)

    :ok = File.write!(output_file, json)
  end
end
```

Generate the file with: `mix myapp.openapispec spec.json`

## Serving the API Spec from a Controller

To serve the API spec from your application, first add the `OpenApiSpex.Plug.PutApiSpec` plug somewhere in the pipeline.

```elixir
  pipeline :api do
    plug OpenApiSpex.Plug.PutApiSpec, module: MyApp.ApiSpec
  end
```

Now the spec will be available for use in downstream plugs.
The `OpenApiSpex.Plug.RenderSpec` plug will render the spec as JSON:

```elixir
  scope "/api" do
    pipe_through :api
    resources "/users", MyApp.UserController, only: [:create, :index, :show]
    get "/openapi", OpenApiSpex.Plug.RenderSpec, []
  end
```

## Use the API Spec to cast params

Add the `OpenApiSpex.Plug.Cast` plug to a controller to cast the request parameters to elixir types defined by the operation schema.

```elixir
plug OpenApiSpex.Plug.Cast, operation_id: "UserController.show"
```

The `operation_id` can be inferred when used from a Phoenix controller from the contents of `conn.private`.

```elixir
defmodule MyApp.UserController do
  use MyAppWeb, :controller
  alias OpenApiSpex.Operation
  alias MyApp.Schemas.{User, UserRequest, UserResponse}

  plug OpenApiSpex.Plug.Cast

  def open_api_operation(action) do
    apply(__MODULE__, "#{action}_operation", [])
  end

  def create_operation do
    import Operation
    %Operation{
      tags: ["users"],
      summary: "Create user",
      description: "Create a user",
      operationId: "UserController.create",
      parameters: [],
      requestBody: request_body("The user attributes", "application/json", UserRequest),
      responses: %{
        201 => response("User", "application/json", UserResponse)
      }
    }
  end

  def create(conn, %UserRequest{user: %User{name: name, email: email, birthday: birthday = %Date{}}}) do
    # params are cast to UserRequest struct
  end
end
```


## Use the API Spec to validate Requests

Add both the `Cast` and `Validate` plugs to your controller / plug:

```elixir
plug OpenApiSpex.Plug.Cast
plug OpenApiSpex.Plug.Validate
```

Now the client will receive a 422 response whenever the request fails to meet the validation rules from the api spec.

## Validating Schema Examples

As schemas evolve, you may want to confirm that the examples given match the schemas.
Use the `OpenApiSpex.Test.Assertions` module to assert on schema validations.

```elixir
Use ExUnit.Case
import OpenApiSpex.Test.Assertions

test "UsersResponse example matches schema" do
  api_spec = MyApp.ApiSpec.spec()
  schema = MyApp.Schemas.UsersResponse.schema()
  assert_schema(schema.example, "UsersResponse", api_spec)
end
```

## Validating API responses in Tests

Api responses can be tested against schemas using `OpenApiSpex.Test.Assertions` also:

```elixir
use MyApp.ConnCase
import OpenApiSpex.Test.Assertions

test "UserController produces a UsersResponse", %{conn: conn} do
  api_spec = MyApp.ApiSpec.spec()
  json =
    conn
    |> get(user_path(conn, :index))
    |> json_response(200)

  assert_schema(json, "UsersResponse", api_spec)
end
```

TODO: SwaggerUI 3.0
