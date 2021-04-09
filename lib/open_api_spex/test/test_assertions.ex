defmodule OpenApiSpex.TestAssertions do
  @moduledoc """
  Defines helpers for testing API responses and examples against API spec schemas.
  """
  import ExUnit.Assertions
  alias OpenApiSpex.OpenApi
  alias OpenApiSpex.Cast.Error
  alias OpenApiSpex.Schema
  alias OpenApiSpex.Reference

  @dialyzer {:no_match, assert_schema: 3}

  @type assert_operation :: :request | :response | nil

  @doc """
  Asserts that `value` conforms to the schema with title `schema_title` in `api_spec`.
  """
  @spec assert_schema(term, String.t(), OpenApi.t(), assert_operation) :: term | no_return
  def assert_schema(value, schema_title, api_spec = %OpenApi{}, assert_operation \\ nil) do
    schemas = api_spec.components.schemas
    schema = schemas[schema_title]

    if !schema do
      flunk("Schema: #{schema_title} not found in #{inspect(Map.keys(schemas))}")
    end

    case OpenApiSpex.cast_value(value, schema, api_spec) do
      {:ok, data} ->
        data

      {:error, errors} ->
        errors =
          errors
          |> Enum.reject(fn error ->
            property = find_property(schema, error.path, schemas)

            ignore_error?(error, property, assert_operation)
          end)
          |> Enum.map(fn error ->
            message = Error.message(error)
            path = Error.path_to_string(error)
            "#{message} at #{path}"
          end)

        if length(errors) > 0 do
          flunk(
            "Value does not conform to schema #{schema_title}: #{Enum.join(errors, "\n")}\n#{
              inspect(value)
            }"
          )
        end
    end
  end

  @doc """
  Asserts that `value` is a valid **response** schema with title `schema_title` in `api_spec`. In this case,
  the presence of required `writeOnly` fields is not validated.
  """
  @spec assert_response_schema(term, String.t(), OpenApi.t()) :: term | no_return
  def assert_response_schema(value, schema_title, api_spec = %OpenApi{}) do
    assert_schema(value, schema_title, api_spec, :response)
  end

  @doc """
  Asserts that `value` is a valid **request** schema with title `schema_title` in `api_spec`. In this case,
  the presence of required `readOnly` fields is not validated.
  """
  @spec assert_request_schema(term, String.t(), OpenApi.t()) :: term | no_return
  def assert_request_schema(value, schema_title, api_spec = %OpenApi{}) do
    assert_schema(value, schema_title, api_spec, :request)
  end

  defp ignore_error?(%Error{reason: :missing_field}, %Schema{readOnly: true}, :request), do: true
  defp ignore_error?(%Error{reason: :missing_field}, %Schema{writeOnly: true}, :response), do: true
  defp ignore_error?(_error, _assert_operation), do: false

  defp find_property(schema, path, schemas) do
    Enum.reduce(path, schema, fn path_item, acc ->
      case acc do
        %Schema{type: :array} ->
          acc.items
          |> OpenApiSpex.resolve_schema(schemas)

        %Schema{} ->
          acc
          |> Map.get(:properties)
          |> Map.get(path_item)
          |> OpenApiSpex.resolve_schema(schemas)
      end
    end)
  end
end
