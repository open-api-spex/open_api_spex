defprotocol OpenApiSpex.Extendable do
  @fallback_to_any true
  def to_map(struct)
end

defimpl OpenApiSpex.Extendable, for: Any do
  def to_map(struct), do: Map.from_struct(struct)
end

defimpl OpenApiSpex.Extendable,
  for: [
    OpenApiSpex.Components,
    OpenApiSpex.Contact,
    OpenApiSpex.Discriminator,
    OpenApiSpex.Encoding,
    OpenApiSpex.Example,
    OpenApiSpex.ExternalDocumentation,
    OpenApiSpex.Header,
    OpenApiSpex.Info,
    OpenApiSpex.License,
    OpenApiSpex.Link,
    OpenApiSpex.MediaType,
    OpenApiSpex.OAuthFlow,
    OpenApiSpex.OAuthFlows,
    OpenApiSpex.OpenApi,
    OpenApiSpex.Operation,
    OpenApiSpex.Parameter,
    OpenApiSpex.PathItem,
    OpenApiSpex.RequestBody,
    OpenApiSpex.Response,
    OpenApiSpex.Schema,
    OpenApiSpex.SecurityScheme,
    OpenApiSpex.Server,
    OpenApiSpex.ServerVariable,
    OpenApiSpex.Tag,
    OpenApiSpex.Xml
  ] do
  def to_map(struct = %{extensions: e}) do
    struct
    |> Map.from_struct()
    |> Map.delete(:extensions)
    |> Map.merge(e || %{})
  end
end
