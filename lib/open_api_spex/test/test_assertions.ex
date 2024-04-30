defmodule OpenApiSpex.TestAssertions do
  @moduledoc """
  Defines helpers for testing API responses and examples against API spec schemas.
  """
  import ExUnit.Assertions
  alias OpenApiSpex.Reference
  alias OpenApiSpex.Cast.{Error, Utils}
  alias OpenApiSpex.{Cast, Components, OpenApi, Operation, Schema}
  alias OpenApiSpex.Plug.PutApiSpec

  @dialyzer {:no_match, assert_schema: 3}

  @json_content_regex ~r/^application\/.*json.*$/

  @doc """
  Asserts that `value` conforms to the schema with title `schema_title` in `api_spec`.
  """
  @spec assert_schema(term, String.t(), OpenApi.t(), Cast.read_write_scope()) :: term | no_return
  def assert_schema(value, schema_title, api_spec = %OpenApi{}, read_write_scope \\ nil) do
    schemas = api_spec.components.schemas
    schema = schemas[schema_title]

    if !schema do
      flunk("Schema: #{schema_title} not found in #{inspect(Map.keys(schemas))}")
    end

    cast_context = %Cast{
      value: value,
      schema: schema,
      schemas: api_spec.components.schemas,
      read_write_scope: read_write_scope
    }

    assert_schema(cast_context)
  end

  @doc """
  Asserts that `value` conforms to the schema or reference definition.
  """
  @spec assert_raw_schema(term, Schema.t() | Reference.t(), OpenApi.t() | %{}) :: term | no_return
  def assert_raw_schema(value, schema, spec \\ %{})

  def assert_raw_schema(value, schema = %Schema{}, spec) do
    schemas = get_or_default_schemas(spec)

    cast_context = %Cast{
      value: value,
      schema: schema,
      schemas: schemas
    }

    assert_schema(cast_context)
  end

  def assert_raw_schema(value, schema = %Reference{}, spec) do
    schemas = get_or_default_schemas(spec)
    resolved_schema = OpenApiSpex.resolve_schema(schema, schemas)

    if is_nil(resolved_schema) do
      flunk("Schema: #{inspect(schema)} not found in #{inspect(spec)}")
    end

    cast_context = %Cast{
      value: value,
      schema: resolved_schema,
      schemas: schemas
    }

    assert_schema(cast_context)
  end

  @spec get_or_default_schemas(OpenApi.t() | %{}) :: Components.schemas_map() | %{}
  defp get_or_default_schemas(api_spec = %OpenApi{}), do: api_spec.components.schemas || %{}
  defp get_or_default_schemas(input), do: input

  @doc """
  Asserts that `value` conforms to the schema in the given `%Cast{}` context.
  """
  @spec assert_schema(Cast.t()) :: term
  def assert_schema(cast_context) do
    case Cast.cast(cast_context) do
      {:ok, data} ->
        data

      {:error, errors} ->
        schema = cast_context.schema

        errors =
          errors
          |> Enum.map(fn error ->
            message = Error.message(error)
            path = Error.path_to_string(error)
            "#{message} at #{path}"
          end)

        if Enum.any?(errors) do
          errors_info = Enum.join(errors, "\n")
          debug_info = "#{schema.title}: #{errors_info}\n#{inspect(cast_context.value)}"
          flunk("Value does not conform to schema #{debug_info}")
        end
    end
  end

  @doc """
  Asserts that `value` is a valid **response** schema with title `schema_title` in `api_spec`. In this case,
  the presence of required `writeOnly` fields is not validated.
  """
  @spec assert_response_schema(term, String.t(), OpenApi.t()) :: term | no_return
  def assert_response_schema(value, schema_title, api_spec = %OpenApi{}) do
    assert_schema(value, schema_title, api_spec, :read)
  end

  @doc """
  Asserts that `value` is a valid **request** schema with title `schema_title` in `api_spec`. In this case,
  the presence of required `readOnly` fields is not validated.
  """
  @spec assert_request_schema(term, String.t(), OpenApi.t()) :: term | no_return
  def assert_request_schema(value, schema_title, api_spec = %OpenApi{}) do
    assert_schema(value, schema_title, api_spec, :write)
  end

  @doc """
  Asserts that the response body conforms to the response schema for the operation with id `operation_id`.
  """
  @spec assert_operation_response(Plug.Conn.t(), String.t() | nil) :: Plug.Conn.t()
  def assert_operation_response(conn, operation_id \\ nil)

  # No need to check for a schema if the response is empty
  def assert_operation_response(conn, _operation_id) when conn.status == 204, do: conn

  def assert_operation_response(conn, operation_id) do
    {spec, operation_lookup} = PutApiSpec.get_spec_and_operation_lookup(conn)

    operation_id = operation_id || conn.private.open_api_spex.operation_id

    case operation_lookup[operation_id] do
      nil ->
        flunk(
          "Failed to resolve a response schema for operation_id: #{operation_id} for status code: #{conn.status}"
        )

      operation ->
        validate_operation_response(conn, operation, spec)
    end

    conn
  end

  if OpenApiSpex.OpenApi.json_encoder() do
    @spec validate_operation_response(
            Plug.Conn.t(),
            Operation.t(),
            OpenApi.t()
          ) ::
            term | no_return
    defp validate_operation_response(conn, %Operation{operationId: operation_id} = operation, spec) do
      content_type = Utils.content_type_from_header(conn, :response)

      responses = Map.get(operation, :responses, %{})
      code_range = String.first(to_string(conn.status)) <> "XX"

      response =
        Map.get(responses, conn.status) ||
          Map.get(responses, "#{conn.status}") ||
          Map.get(responses, :"#{conn.status}") ||
          Map.get(responses, code_range) ||
          Map.get(responses, :"#{code_range}", %{})

      resolved_schema =
        response
        |> Map.get(:content, %{})
        |> Map.get(content_type, %{})
        |> Map.get(:schema)

      if is_nil(resolved_schema) do
        flunk(
          "Failed to resolve a response schema for operation_id: #{operation_id} for status code: #{conn.status} and content type: #{content_type}"
        )
      end

      body =
        if String.match?(content_type, @json_content_regex) do
          OpenApiSpex.OpenApi.json_encoder().decode!(conn.resp_body)
        else
          conn.resp_body
        end

      assert_raw_schema(
        body,
        resolved_schema,
        spec
      )
    end
  else
    defp validate_operation_response(_conn, _operation, _spec) do
      flunk(
        "Unable to use assert_operation_response unless a json encoder is configured. Please add :jason or :poison in your mix dependencies."
      )
    end
  end
end
