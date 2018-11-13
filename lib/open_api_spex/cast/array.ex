defmodule OpenApiSpex.Cast.Array do
  @moduledoc false
  alias OpenApiSpex.{Cast, Error, Validation}

  def cast(%Validation{schema: %{items: nil}, value: value}) when is_list(value) do
    {:ok, value}
  end

  def cast(%Validation{value: items} = validation) when is_list(items) do
    results =
      items
      |> Enum.with_index()
      |> Enum.map(fn {item, index} ->
        case Cast.cast(%{validation | schema: validation.schema.items, value: item, errors: []}) do
          {:ok, cast_item} -> {:ok, cast_item}
          {:error, error_validation} -> {:error, add_to_error_paths(error_validation.errors, index)}
        end
      end)

    {cast_items, errors} = Enum.split_with(results, &match?({:ok, _cast_item}, &1))
    cast_items = Enum.map(cast_items, &elem(&1, 1))
    errors = errors |> Enum.map(&elem(&1, 1)) |> Enum.concat()

    case errors do
      [] -> {:ok, cast_items}
      _ -> {:error, %{validation | errors: errors ++ validation.errors}}
    end
  end

  def cast(%Validation{value: value} = validation) when not is_list(value) do
    {:error, %{validation | errors: [Error.new(:invalid_type, :array, value: value) | validation.errors]}}
  end

  ## Private functions

  # Add an item to the path of each error
  defp add_to_error_paths(errors, item) do
    Enum.map(errors, fn error ->
      %{error | path: [item | error.path]}
    end)
  end
end
