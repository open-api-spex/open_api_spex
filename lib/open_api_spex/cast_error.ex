defmodule OpenApiSpex.CastError do
  alias OpenApiSpex.TermType

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

  def message(%{reason: :invalid_type, type: type, value: value} = ctx) do
    prepend_path("Invalid #{type}: #{inspect(TermType.type(value))}", ctx)
  end

  def message(%{reason: :polymorphic_failed, type: polymorphic_type} = ctx) do
    prepend_path("Failed to cast to any schema in #{polymorphic_type}", ctx)
  end

  def message(%{reason: :unexpected_field, name: name} = ctx) do
    prepend_path("Unexpected field: #{safe_string(name)}", ctx)
  end

  def message(%{reason: :no_value_required_for_discriminator, name: field} = ctx) do
    prepend_path("No value for required disciminator property: #{field}", ctx)
  end

  def message(%{reason: :unknown_schema, name: name} = ctx) do
    prepend_path("Unknown schema: #{name}", ctx)
  end

  def message(%{reason: :missing_field, name: name} = ctx) do
    prepend_path("Missing field: #{name}", ctx)
  end

  defp add_context_fields(error, ctx) do
    %{error | path: Enum.reverse(ctx.path), value: ctx.value}
  end

  defp prepend_path(message, ctx) do
    path = "/" <> (ctx.path |> Enum.map(&to_string/1) |> Path.join())
    "#" <> path <> ": " <> message
  end

  defp safe_string(string) do
    to_string(string) |> String.slice(1..40)
  end
end

defimpl String.Chars, for: OpenApiSpex.CastError do
  def to_string(error) do
    OpenApiSpex.CastError.message(error)
  end
end
