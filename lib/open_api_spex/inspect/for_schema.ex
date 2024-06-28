defimpl Inspect, for: OpenApiSpex.Schema do
  import Inspect.Algebra

  def inspect(parameter, opts) do
    map =
      parameter
      |> Map.from_struct()
      |> Enum.filter(fn
        {_key, nil} -> false
        {_key, _value} -> true
      end)
      |> Map.new()

    infos =
      for %{field: field} = info <- OpenApiSpex.Schema.__info__(:struct),
          Map.has_key?(map, field),
          field not in [:__struct__, :__exception__],
          do: info

     Inspect.Map.inspect(map, Macro.inspect_atom(:literal, OpenApiSpex.Schema), infos, opts)
  end
end
