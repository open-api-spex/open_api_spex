defmodule OpenApiSpex.TestAssertions do
  @moduledoc """
  Defines helpers for testing API responses and examples against API spec schemas.
  """
  import ExUnit.Assertions
  alias OpenApiSpex.Cast.Error
  alias OpenApiSpex.{Cast, OpenApi}

  @dialyzer {:no_match, assert_schema: 3}

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
end
