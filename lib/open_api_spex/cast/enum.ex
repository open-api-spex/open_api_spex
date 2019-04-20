defmodule OpenApiSpex.Cast.Enum do
  @moduledoc false
  alias OpenApiSpex.Cast

  def cast(%Cast{schema: %{enum: []}} = ctx) do
    Cast.error(ctx, {:invalid_enum})
  end

  def cast(%Cast{schema: %{enum: [value | _]}, value: value}) do
    {:ok, value}
  end

  def cast(ctx = %Cast{schema: schema = %{enum: [atom_value | tail]}, value: value})
      when is_binary(value) and is_atom(atom_value) do
    if value == to_string(atom_value) do
      {:ok, atom_value}
    else
      cast(%{ctx | schema: %{schema | enum: tail}})
    end
  end

  def cast(ctx = %Cast{schema: schema = %{enum: [_ | tail]}}) do
    cast(%{ctx | schema: %{schema | enum: tail}})
  end
end
