defmodule OpenApiSpex.Cast.String do
  @moduledoc """

  This module will cast a binary to either an Elixir DateTime or Date. Otherwise it will
  validate a binary based on maxLength, minLength, or a Regex pattern passed through the
  schema struct.

  """
  alias OpenApiSpex.{Cast, Cast.Error}

  @schema_fields [:maxLength, :minLength, :pattern]

  def cast(%{value: value, schema: %{format: :date}} = ctx) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, %Date{} = date} ->
        {:ok, date}

      _ ->
        Cast.error(ctx, {:invalid_format, :date})
    end
  end

  def cast(%{value: value, schema: %{format: :"date-time"}} = ctx) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, %DateTime{} = date_time, _offset} ->
        {:ok, date_time}

      _ ->
        Cast.error(ctx, {:invalid_format, :"date-time"})
    end
  end

  def cast(%{value: value = %Plug.Upload{}, schema: %{format: :binary}}) do
    {:ok, value}
  end

  def cast(%{value: value} = ctx) when is_binary(value) do
    apply_validation(ctx, @schema_fields)
  end

  def cast(ctx) do
    Cast.error(ctx, {:invalid_type, :string})
  end

  ## Private functions

  defp apply_validation(%{value: value, schema: %{maxLength: max_length}} = ctx, [
         :maxLength | fields
       ])
       when is_integer(max_length) do
    if String.length(value) > max_length do
      ctx
      |> apply_error({:max_length, max_length})
      |> apply_validation(fields)
    else
      apply_validation(ctx, fields)
    end
  end

  defp apply_validation(%{value: value, schema: %{minLength: min_length}} = ctx, [
         :minLength | fields
       ])
       when is_integer(min_length) do
    if String.length(value) < min_length do
      ctx
      |> apply_error({:min_length, min_length})
      |> apply_validation(fields)
    else
      apply_validation(ctx, fields)
    end
  end

  defp apply_validation(%{value: value, schema: %{pattern: pattern}} = ctx, [:pattern | fields])
       when not is_nil(pattern) do
    pattern =
      if is_binary(pattern) do
        Regex.compile!(pattern)
      else
        pattern
      end

    if Regex.match?(pattern, value) do
      apply_validation(ctx, fields)
    else
      ctx
      |> apply_error({:invalid_format, pattern})
      |> apply_validation(fields)
    end
  end

  defp apply_validation(ctx, [_field | fields]), do: apply_validation(ctx, fields)
  defp apply_validation(%{value: value, errors: []}, []), do: {:ok, value}
  defp apply_validation(%{errors: errors}, []) when length(errors) > 0, do: {:error, errors}

  defp apply_error(%{errors: errors} = ctx, error_args) do
    Map.put(ctx, :errors, [Error.new(ctx, error_args) | errors])
  end
end
