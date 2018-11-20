defmodule OpenApiSpex.Cast.Primitive do
  @moduledoc false
  alias OpenApiSpex.Cast

  ## boolean

  def cast_boolean(%{value: value}) when is_boolean(value) do
    {:ok, value}
  end

  def cast_boolean(%{value: "true"}), do: {:ok, true}
  def cast_boolean(%{value: "false"}), do: {:ok, false}

  def cast_boolean(ctx) do
    Cast.error(ctx, {:invalid_type, :boolean})
  end

  ## integer

  def cast_integer(%{value: value}) when is_integer(value) do
    {:ok, value}
  end

  def cast_integer(%{value: value}) when is_number(value) do
    {:ok, round(value)}
  end

  def cast_integer(%{value: value} = ctx) when is_binary(value) do
    case Float.parse(value) do
      {value, ""} -> cast_integer(%{ctx | value: value})
      _ -> Cast.error(ctx, {:invalid_type, :integer})
    end
  end

  def cast_integer(ctx) do
    Cast.error(ctx, {:invalid_type, :integer})
  end

  ## number
  def cast_number(%{value: value}) when is_number(value) do
    {:ok, value}
  end

  def cast_number(%{value: value}) when is_integer(value) do
    {:ok, value / 1}
  end

  def cast_number(%{value: value} = ctx) when is_binary(value) do
    case Float.parse(value) do
      {value, ""} -> {:ok, value}
      _ -> Cast.error(ctx, {:invalid_type, :number})
    end
  end

  def cast_number(ctx) do
    Cast.error(ctx, {:invalid_type, :number})
  end
end
