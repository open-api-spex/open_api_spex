defmodule OpenApiSpex.Cast.Primitives do
  @moduledoc false
  alias OpenApiSpex.{Error, Validation}

  ## boolean

  def cast(%Validation{schema: %{type: :boolean}, value: value}) when is_boolean(value) do
    {:ok, value}
  end

  def cast(%Validation{schema: %{type: :boolean}, value: value} = validation)
      when is_binary(value) do
    case value do
      "true" -> {:ok, true}
      "false" -> {:ok, false}
      _ -> {:error, %{validation | errors: [Error.new(:invalid_type, :boolean, value)]}}
    end
  end

  def cast(%Validation{schema: %{type: :boolean}, value: value} = validation) do
    {:error, %{validation | errors: [Error.new(:invalid_type, :boolean, value)]}}
  end

  ## integer

  def cast(%Validation{schema: %{type: :integer}, value: value}) when is_integer(value) do
    {:ok, value}
  end

  def cast(%Validation{schema: %{type: :integer}, value: value} = validation)
      when is_binary(value) do
    case Integer.parse(value) do
      {int_value, ""} -> {:ok, int_value}
      _ ->
        error = Error.new(:invalid_type, :integer, value)
        error = %{error | path: validation.path}
        {:error, %{validation | errors: [error]}}
    end
  end

  def cast(%Validation{schema: %{type: :integer}, value: value} = validation) do
    {:error, %{validation | errors: [Error.new(:invalid_type, :integer, value)]}}
  end

  ## type: :number

  def cast(%Validation{schema: %{type: :number, format: fmt}, value: value})
      when is_integer(value) and fmt in [:float, :double] do
    {:ok, value * 1.0}
  end

  def cast(%Validation{schema: %{type: :number}, value: value}) when is_number(value) do
    {:ok, value}
  end

  def cast(%Validation{schema: %{type: :number}, value: value} = validation)
      when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> {:ok, number}
      _ -> {:error, %{validation | errors: [Error.new(:invalid_type, :number, value)]}}
    end
  end

  def cast(%Validation{schema: %{type: :number}, value: value} = validation) do
    {:error, %{validation | errors: [Error.new(:invalid_type, :number, value)]}}
  end

  ## type: :string

  def cast(%Validation{schema: %{type: :string, format: :"date-time"}, value: value} = validation)
      when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime = %DateTime{}, _offset} -> {:ok, datetime}
      {:error, _reason} -> {:error, %{validation | errors: [Error.new(:invalid_format, :"date-time", value)]}}
    end
  end

  def cast(%Validation{schema: %{type: :string, format: :date}, value: value} = validation)
      when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date = %Date{}} -> {:ok, date}
      {:error, _} -> {:error, %{validation | errors: [Error.new(:invalid_format, :date, value)]}}
    end
  end

  def cast(%Validation{schema: %{type: :string}, value: value}) when is_binary(value) do
    {:ok, value}
  end

  def cast(%Validation{schema: %{type: :string}, value: value} = validation) do
    {:error, %{validation | errors: [Error.new(:invalid_type, :string, value)]}}
  end
end
