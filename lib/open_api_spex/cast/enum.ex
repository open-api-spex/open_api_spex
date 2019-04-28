defmodule OpenApiSpex.Cast.Enum do
  @moduledoc false
  alias OpenApiSpex.Cast

  def cast(ctx = %Cast{schema: %{enum: enum}, value: value}) do
    case Enum.find(enum, {:error, :invalid_enum}, &equivalent?(&1, value)) do
      {:error, :invalid_enum} -> Cast.error(ctx, {:invalid_enum})
      found -> {:ok, found}
    end
  end

  defp equivalent?(x, x), do: true

  # Special case: atoms are equivalent to their stringified representation
  defp equivalent?(left, right) when is_atom(left) and is_binary(right) do
    to_string(left) == right
  end

  # an explicit schema should be used to cast to enum of structs
  defp equivalent?(_x, %_struct{}), do: false

  # Special case: Atom-keyed maps are equivalent to their string-keyed representation
  defp equivalent?(left, right) when is_map(left) and is_map(right) do
    Enum.all?(left, fn {k, v} ->
      equivalent?(v, Map.get(right, to_string(k)))
    end)
  end

  defp equivalent?(_left, _right), do: false
end
