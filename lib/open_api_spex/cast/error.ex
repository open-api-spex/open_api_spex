defmodule OpenApiSpex.Cast.Error do
  alias OpenApiSpex.TermType

  defstruct reason: nil,
            value: nil,
            format: nil,
            type: nil,
            name: nil,
            path: [],
            length: 0,
            meta: %{}

  def new(ctx, {:invalid_schema_type}) do
    %__MODULE__{reason: :invalid_schema_type, type: ctx.schema.type}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:null_value}) do
    type = ctx.schema && ctx.schema.type

    %__MODULE__{reason: :null_value, type: type}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:min_length, length}) do
    %__MODULE__{reason: :min_length, length: length}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:invalid_type, type}) do
    %__MODULE__{reason: :invalid_type, type: type}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:invalid_format, format}) do
    %__MODULE__{reason: :invalid_format, format: format}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:invalid_enum}) do
    %__MODULE__{reason: :invalid_enum}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:unexpected_field, name}) do
    %__MODULE__{reason: :unexpected_field, name: name}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:missing_field, name}) do
    %__MODULE__{reason: :missing_field, name: name}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:max_properties, max_properties, property_count}) do
    %__MODULE__{
      reason: :max_properties,
      meta: %{max_properties: max_properties, property_count: property_count}
    }
    |> add_context_fields(ctx)
  end

  def message(%{reason: :invalid_schema_type, type: type}) do
    "Invalid schema.type. Got: #{inspect(type)}"
  end

  def message(%{reason: :null_value} = error) do
    case error.type do
      nil -> "null value"
      type -> "null value where #{type} expected"
    end
  end

  def message(%{reason: :min_length, length: length}) do
    "String length is smaller than minLength: #{length}"
  end

  def message(%{reason: :invalid_type, type: type, value: value}) do
    "Invalid #{type}. Got: #{TermType.type(value)}"
  end

  def message(%{reason: :invalid_format, format: format}) do
    "Invalid format. Expected #{inspect(format)}"
  end

  def message(%{reason: :invalid_enum}) do
    "Invalid value for enum"
  end

  def message(%{reason: :polymorphic_failed, type: polymorphic_type}) do
    "Failed to cast to any schema in #{polymorphic_type}"
  end

  def message(%{reason: :unexpected_field, name: name}) do
    "Unexpected field: #{safe_string(name)}"
  end

  def message(%{reason: :no_value_required_for_discriminator, name: field}) do
    "No value for required disciminator property: #{field}"
  end

  def message(%{reason: :unknown_schema, name: name}) do
    "Unknown schema: #{name}"
  end

  def message(%{reason: :missing_field, name: name}) do
    "Missing field: #{name}"
  end

  def message(%{reason: :max_properties, meta: meta}) do
    "Object property count #{meta.property_count} is greater than maxProperties: #{
      meta.max_properties
    }"
  end

  def message_with_path(error) do
    prepend_path(error, message(error))
  end

  def path_to_string(%{path: path} = _error) do
    "/" <> (path |> Enum.map(&to_string/1) |> Path.join())
  end

  defp add_context_fields(error, ctx) do
    %{error | path: Enum.reverse(ctx.path), value: ctx.value}
  end

  defp prepend_path(error, message) do
    path =
      case error.path do
        [] -> "#"
        _ -> "#" <> path_to_string(error)
      end

    path <> ": " <> message
  end

  defp safe_string(string) do
    to_string(string) |> String.slice(0..39)
  end
end

defimpl String.Chars, for: OpenApiSpex.Cast.Error do
  def to_string(error) do
    OpenApiSpex.Cast.Error.message(error)
  end
end
