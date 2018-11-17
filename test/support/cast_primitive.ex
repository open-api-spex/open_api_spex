defmodule OpenApiSpex.CastPrimitive do
  @moduledoc false
  alias OpenApiSpex.Error

  def cast(value, _schema, _schemas \\ %{})

  def cast(nil, %{nullable: true}, _schemas),
    do: {:ok, nil}

  def cast(value, %{type: :boolean}, _schemas),
    do: cast_boolean(value)

  def cast(value, %{type: :integer}, _schemas),
    do: cast_integer(value)

  def cast(value, %{type: :number}, _schemas),
    do: cast_number(value)

  def cast(value, %{type: :string}, _schemas),
    do: cast_string(value)

  ## Private functions

  defp cast_boolean(value) when is_boolean(value) do
    {:ok, value}
  end

  defp cast_boolean("true"), do: {:ok, true}
  defp cast_boolean("false"), do: {:ok, false}

  defp cast_boolean(value) do
    {:error, Error.new(:invalid_type, :integer, value)}
  end

  defp cast_integer(value) when is_integer(value) do
    {:ok, value}
  end

  defp cast_integer(value) when is_number(value) do
    {:ok, round(value)}
  end

  defp cast_integer(value) when is_binary(value) do
    case Float.parse(value) do
      {value, ""} -> cast_integer(value)
      _ -> {:error, Error.new(:invalid_type, :integer, value)}
    end
  end

  defp cast_integer(value) do
    {:error, Error.new(:invalid_type, :integer, value)}
  end

  defp cast_number(value) when is_number(value) do
    {:ok, value}
  end

  defp cast_number(value) when is_integer(value) do
    {:ok, value / 1}
  end

  defp cast_number(value) when is_binary(value) do
    case Float.parse(value) do
      {value, ""} -> {:ok, value}
      _ -> {:error, Error.new(:invalid_type, :number, value)}
    end
  end

  defp cast_number(value) do
    {:error, Error.new(:invalid_type, :number, value)}
  end

  defp cast_string(value) when is_binary(value) do
    {:ok, value}
  end

  defp cast_string(value) do
    {:error, Error.new(:invalid_type, :string, value)}
  end
end
