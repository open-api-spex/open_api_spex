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
          do: info

    Inspect.Map.inspect(map, to_doc(OpenApiSpex.Schema, opts), infos, opts)
  end
end
