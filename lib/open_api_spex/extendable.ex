defprotocol OpenApiSpex.Extendable do
  @fallback_to_any true
  def to_map(struct)
end

defimpl OpenApiSpex.Extendable, for: Any do
  def to_map(struct), do: Map.from_struct(struct)
end

defimpl OpenApiSpex.Extendable, for: [OpenApiSpex.Info, OpenApiSpex.OpenApi] do
  def to_map(struct = %{extensions: e}) do
    struct
    |> Map.from_struct()
    |> Map.delete(:extensions)
    |> Map.merge(e || %{})
  end
end
