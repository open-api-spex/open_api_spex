defmodule OpenApiSpex.Cast.Error do
  @moduledoc "OpenApiSpex Cast Error"

  alias OpenApiSpex.TermType

  @type all_of_error :: {:all_of, [String.t()]}
  @type any_of_error :: {:any_of, [String.t()]}
  @type exclusive_max_error :: {:exclusive_max, non_neg_integer(), non_neg_integer()}
  @type exclusive_min_error :: {:exclusive_min, non_neg_integer(), non_neg_integer()}
  @type invalid_enum_error :: {:invalid_enum}
  @type invalid_format_error :: {:invalid_format, any()}
  @type invalid_schema_error :: {:invalid_schema_type}
  @type invalid_type_error :: {:invalid_type, String.t() | atom()}
  @type max_items_error :: {:max_items, non_neg_integer(), non_neg_integer()}
  @type max_length_error :: {:max_length, non_neg_integer()}
  @type max_properties_error :: {:max_properties, non_neg_integer(), non_neg_integer()}
  @type maximum_error :: {:maximum, integer() | float(), integer() | float()}
  @type min_items_error :: {:min_items, non_neg_integer(), non_neg_integer()}
  @type min_length_error :: {:min_length, non_neg_integer()}
  @type min_properties_error :: {:min_properties, non_neg_integer(), non_neg_integer()}
  @type minimum_error :: {:minimum, integer() | float(), integer() | float()}
  @type missing_field_error :: {:missing_field, String.t() | atom()}
  @type missing_header_error :: {:missing_header, String.t() | atom()}
  @type invalid_header_error :: {:invalid_header, String.t() | atom()}
  @type multiple_of_error :: {:multiple_of, non_neg_integer(), non_neg_integer()}
  @type no_value_for_discriminator_error :: {:no_value_for_discriminator, String.t() | atom()}
  @type invalid_discriminator_value_error :: {:invalid_discriminator_value, String.t() | atom()}
  @type null_value_error :: {:null_value}
  @type one_of_error :: {:one_of, [String.t()]}
  @type unexpected_field_error :: {:unexpected_field, String.t() | atom()}
  @type unique_items_error :: {:unique_items}

  @type reason ::
          :all_of
          | :any_of
          | :invalid_schema_type
          | :exclusive_max
          | :exclusive_min
          | :invalid_discriminator_value
          | :invalid_enum
          | :invalid_format
          | :invalid_type
          | :max_items
          | :max_length
          | :max_properties
          | :maximum
          | :min_items
          | :min_length
          | :minimum
          | :missing_field
          | :missing_header
          | :invalid_header
          | :multiple_of
          | :no_value_for_discriminator
          | :null_value
          | :one_of
          | :unexpected_field
          | :unique_items

  @type args ::
          all_of_error()
          | any_of_error()
          | invalid_schema_error()
          | exclusive_max_error()
          | exclusive_min_error()
          | invalid_discriminator_value_error()
          | invalid_enum_error()
          | invalid_format_error()
          | invalid_type_error()
          | max_items_error()
          | max_length_error()
          | max_properties_error()
          | maximum_error()
          | min_items_error()
          | min_length_error()
          | min_properties_error()
          | minimum_error()
          | missing_field_error()
          | missing_header_error()
          | invalid_header_error()
          | multiple_of_error()
          | no_value_for_discriminator_error()
          | null_value_error()
          | one_of_error()
          | unexpected_field_error()
          | unique_items_error()

  @type t :: %__MODULE__{
          reason: reason(),
          value: any(),
          format: String.t(),
          name: String.t(),
          path: list(String.t()),
          length: non_neg_integer(),
          meta: map()
        }

  defstruct reason: nil,
            value: nil,
            format: nil,
            type: nil,
            name: nil,
            path: [],
            length: 0,
            meta: %{}

  @spec new(map(), args()) :: %__MODULE__{}

  def new(ctx, {:invalid_schema_type}) do
    %__MODULE__{reason: :invalid_schema_type, type: ctx.schema.type}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:null_value}) do
    type = ctx.schema && ctx.schema.type

    %__MODULE__{reason: :null_value, type: type}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:all_of, schema_detail}) do
    %__MODULE__{reason: :all_of, meta: %{invalid_schema: schema_detail}}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:any_of, schema_names}) do
    %__MODULE__{reason: :any_of, meta: %{failed_schemas: schema_names}}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:one_of, meta}) do
    %__MODULE__{reason: :one_of, meta: meta}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:min_length, length}) do
    %__MODULE__{reason: :min_length, length: length}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:max_length, length}) do
    %__MODULE__{reason: :max_length, length: length}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:multiple_of, multiple, item_count}) do
    %__MODULE__{reason: :multiple_of, length: multiple, value: item_count}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:unique_items}) do
    %__MODULE__{reason: :unique_items}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:min_items, min_items, item_count}) do
    %__MODULE__{reason: :min_items, length: min_items, value: item_count}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:max_items, max_items, value}) do
    %__MODULE__{reason: :max_items, length: max_items, value: value}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:minimum, minimum, value}) do
    %__MODULE__{reason: :minimum, length: minimum, value: value}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:maximum, maximum, value}) do
    %__MODULE__{reason: :maximum, length: maximum, value: value}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:exclusive_min, exclusive_min, value}) do
    %__MODULE__{reason: :exclusive_min, length: exclusive_min, value: value}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:exclusive_max, exclusive_max, value}) do
    %__MODULE__{reason: :exclusive_max, length: exclusive_max, value: value}
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

  def new(ctx, {:missing_header, name}) do
    %__MODULE__{reason: :missing_header, name: name}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:invalid_header, name}) do
    %__MODULE__{reason: :invalid_header, name: name}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:no_value_for_discriminator, field}) do
    %__MODULE__{reason: :no_value_for_discriminator, name: field}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:invalid_discriminator_value, field}) do
    %__MODULE__{reason: :invalid_discriminator_value, name: field}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:max_properties, max_properties, property_count}) do
    %__MODULE__{
      reason: :max_properties,
      meta: %{max_properties: max_properties, property_count: property_count}
    }
    |> add_context_fields(ctx)
  end

  def new(ctx, {:min_properties, min_properties, property_count}) do
    %__MODULE__{
      reason: :min_properties,
      meta: %{min_properties: min_properties, property_count: property_count}
    }
    |> add_context_fields(ctx)
  end

  @spec message(t()) :: String.t()

  def message(%{reason: :invalid_schema_type, type: type}) do
    "Invalid schema.type. Got: #{inspect(type)}"
  end

  def message(%{reason: :null_value} = error) do
    case error.type do
      nil -> "null value"
      type -> "null value where #{type} expected"
    end
  end

  def message(%{reason: :all_of, meta: %{invalid_schema: invalid_schema}}) do
    "Failed to cast value as #{invalid_schema}. Value must be castable using `allOf` schemas listed."
  end

  def message(%{reason: :any_of, meta: %{failed_schemas: failed_schemas}}) do
    "Failed to cast value using any of: #{failed_schemas}"
  end

  def message(%{reason: :one_of, meta: %{message: message}}) do
    "Failed to cast value to one of: #{message}"
  end

  def message(%{reason: :min_length, length: length}) do
    "String length is smaller than minLength: #{length}"
  end

  def message(%{reason: :max_length, length: length}) do
    "String length is larger than maxLength: #{length}"
  end

  def message(%{reason: :unique_items}) do
    "Array items must be unique"
  end

  def message(%{reason: :min_items, length: min, value: array}) do
    "Array length #{length(array)} is smaller than minItems: #{min}"
  end

  def message(%{reason: :max_items, length: max, value: array}) do
    "Array length #{length(array)} is larger than maxItems: #{max}"
  end

  def message(%{reason: :multiple_of, length: multiple, value: count}) do
    "#{count} is not a multiple of #{multiple}"
  end

  def message(%{reason: :exclusive_max, length: max, value: value})
      when value >= max do
    "#{value} is larger than exclusive maximum #{max}"
  end

  def message(%{reason: :maximum, length: max, value: value})
      when value > max do
    "#{value} is larger than inclusive maximum #{max}"
  end

  def message(%{reason: :exclusive_min, length: min, value: value})
      when value <= min do
    "#{value} is smaller than exclusive minimum #{min}"
  end

  def message(%{reason: :minimum, length: min, value: value})
      when value < min do
    "#{value} is smaller than inclusive minimum #{min}"
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

  def message(%{reason: :no_value_for_discriminator, name: field}) do
    "Value used as discriminator for `#{field}` matches no schemas"
  end

  def message(%{reason: :invalid_discriminator_value, name: field}) do
    "No value provided for required discriminator `#{field}`"
  end

  def message(%{reason: :unknown_schema, name: name}) do
    "Unknown schema: #{name}"
  end

  def message(%{reason: :missing_field, name: name}) do
    "Missing field: #{name}"
  end

  def message(%{reason: :missing_header, name: name}) do
    "Missing header: #{name}"
  end

  def message(%{reason: :invalid_header, name: name}) do
    "Invalid value for header: #{name}"
  end

  def message(%{reason: :max_properties, meta: meta}) do
    "Object property count #{meta.property_count} is greater than maxProperties: #{meta.max_properties}"
  end

  def message(%{reason: :min_properties, meta: meta}) do
    "Object property count #{meta.property_count} is less than minProperties: #{meta.min_properties}"
  end

  def message_with_path(error) do
    prepend_path(error, message(error))
  end

  def path_to_string(%{path: path} = _error) do
    path =
      if path == [] do
        ""
      else
        path |> Enum.map(&to_string/1) |> Path.join()
      end

    "/" <> path
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
