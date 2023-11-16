defmodule OpenApiSpex do
  @moduledoc """
  Provides the entry-points for defining schemas, validating and casting.
  """

  alias OpenApiSpex.{
    Components,
    OpenApi,
    Operation,
    Operation2,
    Reference,
    Schema,
    SchemaConsistency,
    SchemaException,
    SchemaResolver
  }

  alias OpenApiSpex.Cast.{Error, Utils}

  @doc """
  Adds schemas to the api spec from the modules specified in the Operations.

  Eg, if the response schema for an operation is defined with:

      responses: %{
        200 => Operation.response("User", "application/json", UserResponse)
      }

  Then the `UserResponse.schema()` function will be called to load the schema, and
  a `Reference` to the loaded schema will be used in the operation response.

  See `OpenApiSpex.schema` macro for a convenient syntax for defining schema modules.
  """
  @spec resolve_schema_modules(OpenApi.t()) :: OpenApi.t()
  def resolve_schema_modules(spec = %OpenApi{}) do
    SchemaResolver.resolve_schema_modules(spec)
  end

  @doc """
  Add more schemas to an existing OpenApi struct.

  This is useful when the schemas are not used by a Plug or Controller.
  Perhaps they're used by a Phoenix Channel.

  ## Example

      defmodule MyAppWeb.ApiSpec do
        def spec do
          %OpenApiSpex.OpenApi{
            # ...
            paths: OpenApiSpex.Paths.from_router(MyAppWeb.Router)
            # ...
          }
          |> OpenApiSpex.resolve_schema_modules()
          |> OpenApiSpex.add_schemas([
            MyAppWeb.Schemas.Message,
            MyAppWeb.Schemas.Channel
          ])
        end
      end
  """
  @spec add_schemas(OpenApi.t(), list(module)) :: OpenApi.t()
  defdelegate add_schemas(spec, schema_modules), to: SchemaResolver

  @doc """
  Cast and validate a value against a given Schema.
  """
  def cast_value(value, schema = %schema_mod{}) when schema_mod in [Schema, Reference] do
    OpenApiSpex.Cast.cast(schema, value)
  end

  @doc """
  Cast and validate a value against a given Schema belonging to a given OpenApi spec.
  """
  def cast_value(value, schema = %schema_mod{}, spec = %OpenApi{}, opts \\ [])
      when schema_mod in [Schema, Reference] do
    OpenApiSpex.Cast.cast(schema, value, spec.components.schemas, opts)
  end

  @type read_write_scope :: nil | :read | :write

  @type cast_opt ::
          {:replace_params, boolean()}
          | {:apply_defaults, boolean()}
          | {:read_write_scope, read_write_scope()}

  @spec cast_and_validate(
          OpenApi.t(),
          Operation.t(),
          Plug.Conn.t(),
          content_type :: nil | String.t(),
          opts :: [cast_opt()]
        ) :: {:error, [Error.t()]} | {:ok, Plug.Conn.t()}
  def cast_and_validate(
        spec = %OpenApi{},
        operation = %Operation{},
        conn = %Plug.Conn{},
        content_type \\ nil,
        opts \\ []
      ) do
    content_type = content_type || Utils.content_type_from_header(conn)
    Operation2.cast(spec, operation, conn, content_type, opts)
  end

  @doc """
  Cast params to conform to a `OpenApiSpex.Schema`.

  See `OpenApiSpex.Schema.cast/3` for additional examples and details.
  """
  @spec cast(OpenApi.t(), Schema.t() | Reference.t(), any) :: {:ok, any} | {:error, String.t()}
  @deprecated "Use OpenApiSpex.cast_value/3 or cast_value/2 instead"
  def cast(spec = %OpenApi{}, schema = %Schema{}, params) do
    Schema.cast(schema, params, spec.components.schemas)
  end

  def cast(spec = %OpenApi{}, schema = %Reference{}, params) do
    Schema.cast(schema, params, spec.components.schemas)
  end

  @doc """
  Cast all params in `Plug.Conn` to conform to the schemas for `OpenApiSpex.Operation`.

  Returns `{:ok, Plug.Conn.t}` with `params` and `body_params` fields updated if successful,
  or `{:error, reason}` if casting fails.

  `content_type` may optionally be supplied to select the `requestBody` schema.
  """
  @spec cast(OpenApi.t(), Operation.t(), Plug.Conn.t(), content_type | nil) ::
          {:ok, Plug.Conn.t()} | {:error, String.t()}
        when content_type: String.t()
  @deprecated "Use OpenApiSpex.cast_and_validate/3 instead"
  def cast(spec = %OpenApi{}, operation = %Operation{}, conn = %Plug.Conn{}, content_type \\ nil) do
    Operation.cast(operation, conn, content_type, spec.components.schemas)
  end

  @doc """
  Validate params against `OpenApiSpex.Schema`.

  See `OpenApiSpex.Schema.validate/3` for examples of error messages.
  """
  @spec validate(OpenApi.t(), Schema.t() | Reference.t(), any) :: :ok | {:error, String.t()}
  @deprecated "Use OpenApiSpex.cast_value/3 or cast_value/2 instead"
  def validate(spec = %OpenApi{}, schema = %Schema{}, params) do
    Schema.validate(schema, params, spec.components.schemas)
  end

  def validate(spec = %OpenApi{}, schema = %Reference{}, params) do
    Schema.validate(schema, params, spec.components.schemas)
  end

  @doc """
  Validate all params in `Plug.Conn` against `OpenApiSpex.Operation` `parameter` and `requestBody` schemas.

  `content_type` may be optionally supplied to select the `requestBody` schema.
  """
  @spec validate(OpenApi.t(), Operation.t(), Plug.Conn.t(), content_type | nil) ::
          :ok | {:error, String.t()}
        when content_type: String.t()
  @deprecated "Use OpenApiSpex.cast_and_validate/4 instead"
  def validate(
        spec = %OpenApi{},
        operation = %Operation{},
        conn = %Plug.Conn{},
        content_type \\ nil
      ) do
    Operation.validate(operation, conn, content_type, spec.components.schemas)
  end

  def path_to_string(%Error{} = error) do
    Error.path_to_string(error)
  end

  def error_message(%Error{} = error) do
    Error.message(error)
  end

  @doc """
  Declares a struct based `OpenApiSpex.Schema`

   - defines the schema/0 callback
   - ensures the schema is linked to the module by "x-struct" extension property
   - defines a struct with keys matching the schema properties
   - defines a @type `t` for the struct
   - derives a `Jason.Encoder` and/or `Poison.Encoder` for the struct

  See `OpenApiSpex.Schema` for additional examples and details.

  ## Example

      require OpenApiSpex

      defmodule User do
        OpenApiSpex.schema %{
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
          }
        }
      end

  ## Example

  This example shows the `:struct?` and `:derive?` options that may
  be passed to `schema/2`:

      defmodule MyAppWeb.Schemas.User do
        require OpenApiSpex
        alias OpenApiSpex.Schema

        OpenApiSpex.schema(
          %{
            type: :object,
            properties: %{
              name: %Schema{type: :string}
            }
          },
          struct?: false,
          derive?: false
        )
      end

  ## Options

  - `:struct?` (boolean) - When false, prevents the automatic generation
    of a struct definition for the schema module.
  - `:derive?` (boolean) When false, prevents the automatic generation
    of a `@derive` call for either `Poison.Encoder`
    or `Jason.Encoder`. Using this option can
    prevent "... protocol has already been consolidated ..."
    compiler warnings.
  """
  defmacro schema(body, opts \\ []) do
    quote do
      @compile {:report_warnings, false}
      @behaviour OpenApiSpex.Schema
      @schema OpenApiSpex.build_schema(
                unquote(body),
                Keyword.merge([module: __MODULE__], unquote(opts))
              )

      unless Module.get_attribute(__MODULE__, :moduledoc) do
        @moduledoc [@schema.title, @schema.description]
                   |> Enum.reject(&is_nil/1)
                   |> Enum.join("\n\n")
      end

      def schema, do: @schema

      if Map.get(@schema, :"x-struct") == __MODULE__ do
        if Keyword.get(unquote(opts), :derive?, true) do
          @derive Enum.filter([Poison.Encoder, Jason.Encoder], &Code.ensure_loaded?/1)
        end

        if Keyword.get(unquote(opts), :struct?, true) do
          defstruct Schema.properties(@schema)
          @type t :: %__MODULE__{}
        end
      end
    end
  end

  @doc """
  Build a Schema struct from the given keyword list.

  This function adds functionality over defining a
  schema with struct literal sytax using `%OpenApiSpex.Struct{}`:

  - When the `:module` option is given, the `:"x-struct` and `:title`
    attributes of the schema will be autopopulated based on the given
    module
  - Validations are performed on the schema to ensure it is correct.

  ## Options

  - `:module` (module) - A module in the application that the schema
    should be associated with.
  """
  def build_schema(body, opts \\ []) do
    module = opts[:module] || body[:"x-struct"]

    attrs =
      body
      |> Map.delete(:__struct__)
      |> update_in([:"x-struct"], fn struct_module ->
        if Keyword.get(opts, :struct?, true) do
          struct_module || module
        else
          struct_module
        end
      end)
      |> update_in([:title], fn title ->
        title || title_from_module(module)
      end)

    schema = struct(OpenApiSpex.Schema, attrs)

    Map.from_struct(schema) |> OpenApiSpex.validate_compiled_schema()

    # Throwing warnings to prevent runtime bugs (like in issue #144)
    schema
    |> SchemaConsistency.warnings()
    |> Enum.each(&IO.warn("Inconsistent schema: #{&1}", Macro.Env.stacktrace(__ENV__)))

    schema
  end

  def title_from_module(nil), do: nil

  def title_from_module(module) do
    module |> Module.split() |> List.last()
  end

  @doc """
  Creates an `%OpenApi{}` struct from a map.

  This is useful when importing existing JSON or YAML encoded schemas.

  ## Example
      # Importing an existing JSON encoded schema
      open_api_spec_from_json = "encoded_schema.json"
        |> File.read!()
        |> Jason.decode!()
        |> OpenApiSpex.OpenApi.Decode.decode()

      # Importing an existing YAML encoded schema
      open_api_spec_from_yaml = "encoded_schema.yaml"
        |> YamlElixir.read_all_from_file!()
        |> OpenApiSpex.OpenApi.Decode.decode()
  """
  def schema_from_map(map), do: OpenApiSpex.OpenApi.from_map(map)

  @doc """
  Validate the compiled schema's properties to ensure the schema is not improperly
  defined. Only errors which would cause a given schema to _always_ fail should be
  raised here.
  """
  def validate_compiled_schema(schema) do
    Enum.each(schema, fn prop_and_val ->
      :ok = validate_compiled_schema(prop_and_val, schema)
    end)
  end

  def validate_compiled_schema({_, %Schema{} = schema}, _parent) do
    validate_compiled_schema(Map.from_struct(schema))
  end

  @doc """
  Used for validating the schema at compile time, otherwise we're forced
  to raise errors for improperly defined schemas at runtime.
  """
  def validate_compiled_schema({:discriminator, %{propertyName: property, mapping: _}}, %{
        anyOf: schemas
      })
      when is_list(schemas) do
    Enum.each(schemas, fn schema ->
      case schema do
        %Schema{title: title} when is_binary(title) -> :ok
        _ -> error!(:discriminator_schema_missing_title, schema, property_name: property)
      end
    end)
  end

  def validate_compiled_schema({:discriminator, %{propertyName: _, mapping: _}}, schema) do
    case {schema.anyOf, schema.allOf, schema.oneOf} do
      {nil, nil, nil} ->
        error!(:discriminator_missing_composite_key, schema)

      _ ->
        :ok
    end
  end

  def validate_compiled_schema({_property, _value}, _schema), do: :ok

  @doc """
  Raises compile time errors for improperly defined schemas.
  """
  @spec error!(atom(), Schema.t(), keyword()) :: no_return()
  @spec error!(atom(), Schema.t()) :: no_return()
  def error!(error, schema, details \\ []) do
    raise SchemaException, %{error: error, schema: schema, details: details}
  end

  @doc """
  Resolve a schema or reference to a schema.
  """
  @spec resolve_schema(Schema.t() | Reference.t() | module, Components.schemas_map()) ::
          Schema.t() | nil
  def resolve_schema(%Schema{} = schema, _), do: schema
  def resolve_schema(%Reference{} = ref, schemas), do: Reference.resolve_schema(ref, schemas)

  def resolve_schema(mod, _) when is_atom(mod) do
    IO.warn("""
    Unresolved schema module: #{inspect(mod)}.
    Use OpenApiSpex.resolve_schema_modules/1 to resolve modules ahead of time.
    """)

    mod.schema()
  end

  @doc """
  Get casted body params from a `Plug.Conn`.
  If the conn has not been yet casted `nil` is returned.
  """
  @spec body_params(Plug.Conn.t()) :: nil | map()
  def body_params(%Plug.Conn{} = conn), do: get_in(conn.private, [:open_api_spex, :body_params])

  @doc """
  Get casted params from a `Plug.Conn`.
  If the conn has not been yet casted `nil` is returned.
  """
  @spec params(Plug.Conn.t()) :: nil | map()
  def params(%Plug.Conn{} = conn), do: get_in(conn.private, [:open_api_spex, :params])

  @doc """

  """
  @spec add_parameter_content_parser(
          OpenApi.t(),
          content_type | [content_type],
          parser :: module()
        ) :: OpenApi.t()
        when content_type: String.t() | Regex.t()
  def add_parameter_content_parser(%OpenApi{extensions: ext} = spec, content_type, parser) do
    extensions = ext || %{}

    param_parsers = Map.get(extensions, "x-parameter-content-parsers", %{})

    param_parsers =
      content_type
      |> List.wrap()
      |> Enum.reduce(param_parsers, fn ct, acc -> Map.put(acc, ct, parser) end)

    %OpenApi{spec | extensions: Map.put(extensions, "x-parameter-content-parsers", param_parsers)}
  end
end
