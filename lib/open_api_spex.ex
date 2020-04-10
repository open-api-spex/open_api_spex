defmodule OpenApiSpex do
  @moduledoc """
  Provides the entry-points for defining schemas, validating and casting.
  """

  alias OpenApiSpex.{
    Components,
    OpenApi,
    Operation,
    Reference,
    Schema,
    SchemaException,
    SchemaResolver,
    SchemaConsistency
  }

  alias OpenApiSpex.Cast.Error

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
  Cast and validate a value against a given Schema.
  """
  def cast_value(value, schema = %schema_mod{}) when schema_mod in [Schema, Reference] do
    OpenApiSpex.Cast.cast(schema, value)
  end

  @doc """
  Cast and validate a value against a given Schema belonging to a given OpenApi spec.
  """
  def cast_value(value, schema = %schema_mod{}, spec = %OpenApi{})
      when schema_mod in [Schema, Reference] do
    OpenApiSpex.Cast.cast(schema, value, spec.components.schemas)
  end

  def cast_and_validate(
        spec = %OpenApi{},
        operation = %Operation{},
        conn = %Plug.Conn{},
        content_type \\ nil
      ) do
    Operation.cast(operation, conn, content_type, spec.components)
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
  """
  defmacro schema(body) do
    quote do
      @compile {:report_warnings, false}
      @behaviour OpenApiSpex.Schema
      @schema struct(
                OpenApiSpex.Schema,
                unquote(body)
                |> Map.delete(:__struct__)
                |> Map.put(:"x-struct", __MODULE__)
                |> update_in([:title], fn title ->
                  title || __MODULE__ |> Module.split() |> List.last()
                end)
              )

      def schema, do: @schema

      @derive Enum.filter([Poison.Encoder, Jason.Encoder], &Code.ensure_loaded?/1)
      defstruct Schema.properties(@schema)
      @type t :: %__MODULE__{}

      Map.from_struct(@schema) |> OpenApiSpex.validate_compiled_schema()

      # Throwing warnings to prevent runtime bugs (like in issue #144)
      @schema
      |> SchemaConsistency.warnings()
      |> Enum.each(&IO.warn("Inconsistent schema: #{&1}", Macro.Env.stacktrace(__ENV__)))
    end
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
  @spec resolve_schema(Schema.t() | Reference.t(), Components.schemas_map()) :: Schema.t()
  def resolve_schema(%Schema{} = schema, _), do: schema
  def resolve_schema(%Reference{} = ref, schemas), do: Reference.resolve_schema(ref, schemas)
end
