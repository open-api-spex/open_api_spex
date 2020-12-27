defmodule OpenApiSpex.ControllerSpecs do
  @moduledoc """
  Macros for defining operation specs, shared operation tags, and shared security specs
  in a Phoenix controller.

  ## Example

  Here is an example Phoenix controller that uses the ControllerSpecs Operation specs:

      defmodule MyAppWeb.UserController do
        use Phoenix.Controller
        use OpenApiSpex.ControllerSpecs

        alias MyAppWeb.Schemas.{UserParams, UserResponse}

        tags ["users"]
        security [%{}, %{"petstore_auth" => ["write:users", "read:users"]}]

        operation :update,
          summary: "Update user",
          parameters: [
            id: [
              in: :path,
              description: "User ID",
              type: :integer,
              example: 1001
            ]
          ],
          request_body: {"User params", "application/json", UserParams},
          responses: [
            ok: {"User response", "application/json", UserResponse}
          ]

        def update(conn, %{"id" => id}) do
          json(conn, %{
            data: %{
              id: id,
              name: "joe user",
              email: "joe@gmail.com"
            }
          })
        end
      end

  If you use Elixir Formatter, `:open_api_spex` can be added to the `:import_deps`
  list in the `.formatter.exs` file of your project to make parentheses of the
  macros optional.
  """
  alias OpenApiSpex.{Operation, OperationBuilder}

  defmacro __using__(_opts) do
    quote do
      import OpenApiSpex.ControllerSpecs

      Module.register_attribute(__MODULE__, :spec_attributes, accumulate: true)
      Module.register_attribute(__MODULE__, :shared_tags, accumulate: true)
      Module.register_attribute(__MODULE__, :shared_security, accumulate: true)

      @before_compile {OpenApiSpex.ControllerSpecs, :before_compile}

      @spec open_api_operation(atom()) :: OpenApiSpex.Operation.t()
    end
  end

  @doc """
  Defines an Operation spec for a controller action.

  ## Example

      operation :update,
        summary: "Update user",
        description: "Updates a user record from the given ID path paramter and request body parameters.",
        parameters: [
          id: [
            in: :path,
            description: "User ID",
            type: :integer,
            example: 1001
          ]
        ],
        request_body: {"User params", "application/json", UserParams},
        responses: [
          ok: {"User response", "application/json", UserResponse}
        ],
        security: [%{}, %{"petstore_auth" => ["write:pets", "read:pets"]}],
        tags: ["users"]

  ## Options

  These options correlate to the
  [Operation fields specified in the Open API spec](https://swagger.io/specification/#operation-object).
  One difference however, is that the fields defined in Open API use `camelCase` naming,
  while the fields used in `ControllerSpecs` use `snake_case` to match Elixir's convention.

  - `summary` The operation summary
  - `parameters` The endpoint's parameters. The syntax for `parameters` can take multiple forms:
    - The common form is a keyword list, where each key is the parameter name, and the value
      is a keyword list of options that correlate to the fields in an
      [Open API Parameter Object](https://swagger.io/specification/#parameter-object).
      For example:

      ```elixir
        parameters: [
          id: [
            in: :path,
            description: "User ID",
            type: :integer,
            example: 1001
          ]
        ]
      ```
    - A `parameters` list can also contain references to parameter schemas. There are two
      ways to do that:

      ```elixir
      parameters: [
        "$ref": "#/components/parameters/user_id"
        # or
        %OpenApiSpex.Reference{"$ref": "#/components/parameters/user_id"}
      ]
      ```
  - `request_body` The endpoint's request body. There are multiple ways to specifiy a request body:
    - A three or four-element tuple:

        ```elixir
        request_body: {
          "User update request body",
          "application/json",
          UserUpdateRequest,
          required: true
        }
        ```

      The tuple consists of the following:
      1. The description
      2. The content-type
      3. An Open API schema. This can be a schema module that implements the
         `OpenApiSpex.Schema` [behaviour](https://hexdocs.pm/elixir/Module.html#module-behaviour),
         or an `OpenApiSpex.Schema` struct.
      4. A optional keyword list of options. There is only one option available,
         and that is `required: boolean`.
  - `responses` The endpoint's responses, for each HTTP status code the endpoint may respond with.
    Multiple syntaxes are supported:
    - A common syntax is a keyword list, where each key is the textual name of an HTTP status code.
      For example:

        ```elixir
        [
          ok: {"User response", "application/json", User},
          not_found: {"User not found", "application/json", NotFound}
        ]
        ```

      The list of names and their code mappings is defined in
      `Plug.Conn.Status.code/1`.

    - If a map is used, the keys can either be the same atom keys used
      in the keyword syntax (`%{ok: ...}`), or they can be integers representing
      the HTTP status code directly:

        ```elixir
        responses: %{
          200 => {"User response", "application/json", User},
          404 => {"User not found", "application/json", NotFound}
        }
        ```

    - Each response can be a three-element tuple:

        ```elixir
        responses: [
          ok: {"User response", "application/json", User}
          # Or
          ok: {"User response", "application/json", %OpenApiSpex.Schema{...}}
        ]
        ```

      This tuple consists of:
      1. A Description string
      2. A content-type string
      3. An Open API schema. This can be a schema module that implements the
         `OpenApiSpex.Schema` [behaviour](https://hexdocs.pm/elixir/Module.html#module-behaviour),
         or an `OpenApiSpex.Schema` struct.

    - If the response represents an empty response, the definition value can
      be a single string representing the response description. For example:

        ```elixir
        responses: [
          no_content: "Empty response"
        ]
        ```

    - A response can also be defined as an `OpenApiSpex.RequestBody` struct. In fact, all
      response body syntaxes resolve to this struct.

  - Additional fields: There are other Operation fields that can be specified that are not
    described here. See `OpenApiSpex.Operation` for all the fields.
  """
  @spec operation(action :: atom, spec :: map) :: any
  defmacro operation(action, spec) do
    quote do
      @spec_attributes {unquote(action),
                        operation_spec(__MODULE__, unquote(action), unquote(spec))}

      def open_api_operation(unquote(action)) do
        @spec_attributes[unquote(action)]
      end
    end
  end

  @doc """
  Defines a list of tags that all operations in a controller will share.

  ## Example

      tags ["users"]

  All operations defined in the controller will inherit the tags specified
  by this call. If an operation defines its own tags, the tags in this call
  will be appended to the operation's tags.
  """
  @spec tags(tags :: [String.t()]) :: any
  defmacro tags(tags) do
    quote do
      @shared_tags unquote(tags)
    end
  end

  @doc """
  Defines security requirements shared by all operations defined in a controller.

  See [Security Requirement Object spec](https://swagger.io/specification/#securityRequirementObject)
  and `OpenApiSpex.SecurityRequirement` for more information.
  """
  @spec security([%{required(String.t()) => [String.t()]}]) :: any
  defmacro security(requirements) do
    quote do
      @shared_security unquote(requirements)
    end
  end

  @doc false
  defmacro before_compile(_env) do
    quote do
      def open_api_operation(action) do
        module_name = __MODULE__ |> to_string() |> String.replace_leading("Elixir.", "")
        IO.warn("No operation spec defined for controller action #{module_name}.#{action}")
      end

      def shared_tags, do: @shared_tags

      def shared_security, do: @shared_security
    end
  end

  @doc """
  Define an Operation for a controller action.

  See `OpenApiSpex.ControllerSpecs` for usage and examples.
  """
  def operation_spec(_module, _action, nil = _spec), do: nil

  def operation_spec(module, action, spec) do
    spec = Map.new(spec)
    shared_tags = Module.get_attribute(module, :shared_tags, []) |> List.flatten()
    security = Module.get_attribute(module, :shared_security, []) |> List.flatten()

    %Operation{
      description: Map.get(spec, :description),
      deprecated: Map.get(spec, :deprecated),
      operationId: OperationBuilder.build_operation_id(spec, module, action),
      parameters: OperationBuilder.build_parameters(spec),
      requestBody: OperationBuilder.build_request_body(spec),
      responses: OperationBuilder.build_responses(spec),
      security: OperationBuilder.build_security(spec, %{security: security}),
      summary: Map.get(spec, :summary),
      tags: OperationBuilder.build_tags(spec, %{tags: shared_tags})
    }
  end
end
