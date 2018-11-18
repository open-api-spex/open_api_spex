defmodule OpenApiSpex.CastPrimitive do
  @moduledoc false
  alias OpenApiSpex.CastContext

  def cast(%{value: nil, schema: %{nullable: true}}),
    do: {:ok, nil}

  def cast(%{schema: %{type: :boolean}} = ctx),
    do: cast_boolean(ctx)

  def cast(%{schema: %{type: :integer}} = ctx),
    do: cast_integer(ctx)

  def cast(%{schema: %{type: :number}} = ctx),
    do: cast_number(ctx)

  def cast(%{schema: %{type: :string}} = ctx),
    do: cast_string(ctx)

  ## Private functions

  defp cast_boolean(%{value: value}) when is_boolean(value) do
    {:ok, value}
  end

  defp cast_boolean(%{value: "true"}), do: {:ok, true}
  defp cast_boolean(%{value: "false"}), do: {:ok, false}

  defp cast_boolean(ctx) do
    CastContext.error(ctx, {:invalid_type, :boolean})
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
      _ -> CastContext.error(ctx, {:invalid_type, :integer})
    end
  end

  defp cast_integer(ctx) do
    CastContext.error(ctx, {:invalid_type, :integer})
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
      _ -> CastContext.error(ctx, {:invalid_type, :number})
    end
  end

  defp cast_number(ctx) do
    CastContext.error(ctx, {:invalid_type, :number})
  end

  defp cast_string(%{value: value, schema: %{pattern: pattern}} = ctx)
       when not is_nil(pattern) and is_binary(value) do
    if Regex.match?(pattern, value) do
      {:ok, value}
    else
      CastContext.error(ctx, {:invalid_format, pattern})
    end
  end

  defp cast_string(%{value: value}) when is_binary(value) do
    {:ok, value}
  end

  defp cast_string(ctx) do
    CastContext.error(ctx, {:invalid_type, :string})
  end
end
