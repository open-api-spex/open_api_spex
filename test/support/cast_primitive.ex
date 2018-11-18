defmodule OpenApiSpex.CastPrimitive do
  @moduledoc false
  alias OpenApiSpex.Error

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
    error(:invalid_type, :boolean, ctx)
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
      _ -> error(:invalid_type, :integer, ctx)
    end
  end

  defp cast_integer(ctx) do
    error(:invalid_type, :integer, ctx)
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
      _ -> error(:invalid_type, :number, ctx)
    end
  end

  defp cast_number(ctx) do
    error(:invalid_type, :number, ctx)
  end

  defp cast_string(%{value: value, schema: %{pattern: pattern}})
       when not is_nil(pattern) and is_binary(value) do
    if Regex.match?(pattern, value) do
      {:ok, value}
    else
      {:error, Error.new(:invalid_format, pattern, value)}
    end
  end

  defp cast_string(%{value: value}) when is_binary(value) do
    {:ok, value}
  end

  defp cast_string(ctx) do
    error(:invalid_type, :string, ctx)
  end

  defp error(:invalid_type, expected_type, ctx) do
    error = Error.new(:invalid_type, expected_type, ctx.value)
    error = %{error | path: Enum.reverse(ctx.path)}
    {:error, [error | ctx.errors]}
  end
end
