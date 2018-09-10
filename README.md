# Open API Spex
[![Build Status](https://travis-ci.org/mbuhot/open_api_spex.svg?branch=master)](https://travis-ci.org/mbuhot/open_api_spex)
[![Hex.pm](https://img.shields.io/hexpm/v/open_api_spex.svg)](https://hex.pm/packages/open_api_spex)


Leverage Open Api Specification 3 (swagger) to document, test, validate and explore your Plug and Phoenix APIs.

 - Generate and serve a JSON Open Api Spec document from your code
 - Use the spec to cast request params to well defined schema structs
 - Validate params against schemas, eliminate bad requests before they hit your controllers
 - Validate responses against schemas in tests, ensuring your docs are accurate and reliable
 - Explore the API interactively with with [SwaggerUI](https://swagger.io/swagger-ui/)

Full documentation available on [hexdocs](https://hexdocs.pm/open_api_spex/)

## Installation

The package can be installed by adding `open_api_spex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:open_api_spex, "~> 2.3"}
  ]
end
```

## Generate Spec

Start by adding an `ApiSpec` module to your application to populate an `OpenApiSpex.OpenApi` struct.

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
It will be passed the plug opts that were declared in the router, this will be the action for a phoenix controller. The callback populates an `OpenApiSpex.Operation` struct describing the plug/action.

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
Each module should implement the `OpenApiSpex.Schema` behaviour.
The only callback is `schema/0`, which should return an `OpenApiSpex.Schema` struct.
You may optionally declare a struct, linked to the JSON schema through the `x-struct` extension property.
See `OpenApiSpex.schema/1` macro for a convenient way to reduce some boilerplate.

```elixir
defmodule MyApp.Schemas do
  alias OpenApiSpex.Schema

  defmodule User do
    @behaviour OpenApiSpex.Schema
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
      example: %{
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
    require OpenApiSpex

    # OpenApiSpex.schema/1 macro can be optionally used to reduce boilerplate code
    OpenApiSpex.schema %{
      title: "UserResponse",
      description: "Response schema for single user",
      type: :object,
      properties: %{
        data: User
      }
    }
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

## Serve Spec

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

## Serve Swagger UI

Once your API spec is available through a route, the `OpenApiSpex.Plug.SwaggerUI` plug can be used to serve a SwaggerUI interface.  The `path:` plug option must be supplied to give the path to the API spec.

All javascript and CSS assets are sourced from cdnjs.cloudflare.com, rather than vendoring into this package.

```elixir
  scope "/" do
    pipe_through :browser # Use the default browser stack

    get "/", MyAppWeb.PageController, :index
    get "/swaggerui", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"
  end

  scope "/api" do
    pipe_through :api

    resources "/users", MyAppWeb.UserController, only: [:create, :index, :show]
    get "/openapi", OpenApiSpex.Plug.RenderSpec, []
  end
```

## Cast Params

Add the `OpenApiSpex.Plug.Cast` plug to a controller to cast the request parameters and body to elixir types defined by the operation schema.

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
    apply(__MODULE__, :"#{action}_operation", [])
  end

  def create_operation do
    import Operation
    %Operation{
      tags: ["users"],
      summary: "Create user",
      description: "Create a user",
      operationId: "UserController.create",
      parameters: [
        parameter(:id, :query, :integer, "user ID")
      ],
      requestBody: request_body("The user attributes", "application/json", UserRequest),
      responses: %{
        201 => response("User", "application/json", UserResponse)
      }
    }
  end

  def create(conn = %{body_params: %UserRequest{user: %User{name: name, email: email, birthday: birthday = %Date{}}}}, %{id: id}) do
    # conn.body_params cast to UserRequest struct
    # conn.params.id cast to integer
  end
end
```
See also `OpenApiSpex.cast/3` and `OpenApiSpex.Schema.cast/3` for more examples outside of a `plug` pipeline.


## Validate Params

Add both the `OpenApiSpex.Plug.Cast` and `OpenApiSpex.Plug.Validate` plugs to your controller / plug:

```elixir
plug OpenApiSpex.Plug.Cast
plug OpenApiSpex.Plug.Validate
```

Now the client will receive a 422 response whenever the request fails to meet the validation rules from the api spec.

The response body will include the validation error message:

```
#/user/name: Value does not match pattern: [a-zA-Z][a-zA-Z0-9_]+
```

See `OpenApiSpex.validate/3` and `OpenApiSpex.Schema.validate/3` for usage outside of a plug pipeline.

## Validate Examples

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

## Validate Responses

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
