defmodule OpenApiSpex.CastError do
  defstruct reason: nil,
            value: nil,
            format: nil,
            type: nil,
            name: nil,
            path: []

  def new(ctx, {:invalid_type, type}) do
    %__MODULE__{reason: :invalid_type, type: type}
    |> add_context_fields(ctx)
  end

  def new(ctx, {:invalid_format, format}) do
    %__MODULE__{reason: :invalid_format, format: format}
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

  def message(%{reason: :invalid_type, type: type, value: value}) do
    "Invalid #{type}: #{inspect(value)}"
  end

  def message(%{reason: :polymorphic_failed, type: polymorphic_type}) do
    "Failed to cast to any schema in #{polymorphic_type}"
  end

  def message(%{reason: :unexpected_field, value: value}) do
    "Unexpected field with value #{inspect(value)}"
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

  defp add_context_fields(error, ctx) do
    %{error | path: Enum.reverse(ctx.path), value: ctx.value}
  end
end

defimpl String.Chars, for: OpenApiSpex.CastError do
  def to_string(error) do
    OpenApiSpex.CastError.message(error)
  end
end
