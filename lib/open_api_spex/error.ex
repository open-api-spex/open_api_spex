defmodule OpenApiSpex.Error do
  defstruct [:reason, :value, :format, :type, :path]

  def new(:invalid_type, type, value) do
    %__MODULE__{reason: :invalid_type, type: type, value: value}
  end

  def new(:polymorphic_failed, value, polymorphic_type) do
    %__MODULE__{reason: :polymorphic_failed, value: value, type: polymorphic_type}
  end

  def new(:invalid_format, format, value) do
    %__MODULE__{reason: :invalid_type, format: format, value: value}
  end

  def new(:unexpected_field, value) do
    %__MODULE__{reason: :unexpected_field, value: value}
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
end

defimpl String.Chars, for: OpenApiSpex.Error do
  def to_string(error) do
    OpenApiSpex.Error.message(error)
  end
end
