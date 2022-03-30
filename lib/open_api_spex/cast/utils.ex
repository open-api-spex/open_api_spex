defmodule OpenApiSpex.Cast.Utils do
  @moduledoc false

  # Merge 2 maps considering as equal keys that are atom or string representation
  # of that atom. Atom keys takes precedence over string ones.
  def merge_maps(map1, map2) do
    l1 = Enum.map(map1, fn {key, val} -> {to_string(key), key, val} end)
    l2 = Enum.map(map2, fn {key, val} -> {to_string(key), key, val} end)

    l1
    |> Kernel.++(l2)
    |> Enum.group_by(fn {ks, _, _} -> ks end, fn {_, k, v} -> {k, v} end)
    |> Map.new(fn
      {_ks, [{k, v}]} ->
        {k, v}

      {_ks, [{k1, v1}, {k2, v2}]} ->
        cond do
          is_atom(k2) -> {k2, v2}
          is_atom(k1) -> {k1, v1}
          true -> {k2, v2}
        end
    end)
  end
end
