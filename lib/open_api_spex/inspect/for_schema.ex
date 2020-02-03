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

    concat(["%OpenApiSpex.Schema", to_doc(map, opts)])
  end
end
