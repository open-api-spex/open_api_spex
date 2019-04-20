defmodule OpenApiSpex.Cast.Enum do
  @moduledoc false
  alias OpenApiSpex.Cast

  def cast(%Cast{schema: %{enum: []}} = ctx) do
    Cast.error(ctx, {:invalid_enum})
  end

  def cast(%Cast{schema: %{enum: [value | _]}, value: value}) do
    {:ok, value}
  end

  # Special case: convert binary to atom enum
  def cast(ctx = %Cast{schema: schema = %{enum: [atom_value | tail]}, value: value})
      when is_binary(value) and is_atom(atom_value) do
    if value == to_string(atom_value) do
      {:ok, atom_value}
    else
      cast(%{ctx | schema: %{schema | enum: tail}})
    end
  end

  # Special case: convert string-keyed map to atom-keyed map enum
  def cast(ctx = %Cast{schema: schema = %{enum: [enum_map = %{} | tail]}, value: value = %{}}) do
    if maps_equivalent?(value, enum_map) do
      {:ok, enum_map}
    else
      cast(%{ctx | schema: %{schema | enum: tail}})
    end
  end

  def cast(ctx = %Cast{schema: schema = %{enum: [_ | tail]}}) do
    cast(%{ctx | schema: %{schema | enum: tail}})
  end

  defp maps_equivalent?(x, x), do: true

  # an explicit schema should be used to cast to enum of structs
  defp maps_equivalent?(_left, %_struct{}), do: false

  defp maps_equivalent?(left = %{}, right = %{}) when map_size(left) == map_size(right) do
    Enum.all?(right, fn {k, v} ->
      maps_equivalent?(Map.get(left, to_string(k)), v)
    end)
  end

  defp maps_equivalent?(_left, _right), do: false
end
