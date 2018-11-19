defmodule OpenApiSpex.Cast.Primitive do
  @moduledoc false
  alias OpenApiSpex.Cast.{Context, String}

  def cast(%{schema: %{type: :boolean}} = ctx),
    do: cast_boolean(ctx)

  def cast(%{schema: %{type: :integer}} = ctx),
    do: cast_integer(ctx)

  def cast(%{schema: %{type: :number}} = ctx),
    do: cast_number(ctx)

  def cast(%{schema: %{type: :string}} = ctx),
    do: String.cast(ctx)

  ## Private functions

  defp cast_boolean(%{value: value}) when is_boolean(value) do
    {:ok, value}
  end

  defp cast_boolean(%{value: "true"}), do: {:ok, true}
  defp cast_boolean(%{value: "false"}), do: {:ok, false}

  defp cast_boolean(ctx) do
    Context.error(ctx, {:invalid_type, :boolean})
  end

  defp cast_integer(%{value: value}) when is_integer(value) do
    {:ok, value}
  end

  defp cast_integer(%{value: value}) when is_number(value) do
    {:ok, round(value)}
  end

  defp cast_integer(%{value: value} = ctx) when is_binary(value) do
    case Float.parse(value) do
      {value, ""} -> cast_integer(%{ctx | value: value})
      _ -> Context.error(ctx, {:invalid_type, :integer})
    end
  end

  defp cast_integer(ctx) do
    Context.error(ctx, {:invalid_type, :integer})
  end

  defp cast_number(%{value: value}) when is_number(value) do
    {:ok, value}
  end

  defp cast_number(%{value: value}) when is_integer(value) do
    {:ok, value / 1}
  end

  defp cast_number(%{value: value} = ctx) when is_binary(value) do
    case Float.parse(value) do
      {value, ""} -> {:ok, value}
      _ -> Context.error(ctx, {:invalid_type, :number})
    end
  end

  defp cast_number(ctx) do
    Context.error(ctx, {:invalid_type, :number})
  end
end
