defimpl Inspect, for: OpenApiSpex.Schema do
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

    do_inspect(map, "OpenApiSpex.Schema", infos, opts)
  end

  if Version.compare(System.version(), "1.19.0") in [:gt, :eq] do
    defp do_inspect(map, schema_mod, infos, opts) do
      Inspect.Map.inspect_as_struct(map, schema_mod, infos, opts)
    end
  else
    defp do_inspect(map, schema_mod, infos, opts) do
      Inspect.Map.inspect(map, schema_mod, infos, opts)
    end
  end
end
