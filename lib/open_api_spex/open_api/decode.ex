defmodule OpenApiSpex.OpenApi.Decode do
  @moduledoc "This module exposes functionality to convert an arbitrary map into a OpenApi struct."

  alias OpenApiSpex.{
    Components,
    Contact,
    Discriminator,
    Encoding,
    Example,
    ExternalDocumentation,
    Header,
    Info,
    License,
    Link,
    MediaType,
    OAuthFlow,
    OAuthFlows,
    OpenApi,
    Operation,
    Parameter,
    PathItem,
    Reference,
    RequestBody,
    Response,
    Schema,
    SecurityScheme,
    Server,
    ServerVariable,
    Tag,
    Xml
  }

  @open_api_spex_extensions ["x-struct", "x-validate"]

  def decode(%{"openapi" => _openapi, "info" => _info, "paths" => _paths} = map) do
    map
    |> to_struct(OpenApi)
    |> prop_to_struct(:info, Info)
    |> prop_to_struct(:paths, PathItems)
    |> prop_to_struct(:servers, Servers)
    |> prop_to_struct(:components, Components)
    |> prop_to_struct(:tags, Tag)
    |> prop_to_struct(:externalDocs, ExternalDocumentation)
    |> add_extensions(map)
  end

  defp struct_from_map(struct, map) when is_atom(struct) do
    struct_from_map(struct.__struct__(), map)
  end

  defp struct_from_map(%_{} = struct, map) do
    keys = struct |> Map.from_struct() |> Map.keys()

    Enum.reduce(keys, struct, fn key, struct ->
      case map_get(map, key) do
        {_, value} -> Map.put(struct, key, value)
        _ -> struct
      end
    end)
  end

  defp map_get(map, atom_key) when is_atom(atom_key) do
    case map do
      %{^atom_key => value} ->
        {atom_key, value}

      _ ->
        map_get(map, to_string(atom_key))
    end
  end

  defp map_get(map, string_key) when is_binary(string_key) do
    case map do
      %{^string_key => value} -> {string_key, value}
      _ -> nil
    end
  end

  defp embedded_ref_or_struct(list, mod) when is_list(list) do
    list
    |> Enum.map(fn
      %{"$ref" => _} = v -> struct_from_map(Reference, v)
      v -> to_struct(v, mod)
    end)
  end

  defp embedded_ref_or_struct(map, mod) when is_map(map) do
    map
    |> Map.new(fn
      {k, %{"$ref" => _} = v} ->
        {k, struct_from_map(Reference, v)}

      {k, v} ->
        {k, to_struct(v, mod)}
    end)
  end

  defp update_map_if_key_present(map, key, fun) do
    case map do
      %{^key => value} -> %{map | key => fun.(value)}
      %{} -> map
    end
  end

  # In some cases, e.g. Schema type we must convert values that are strings to atoms,
  # for example Schema.type should be one of:
  #
  # :string | :number | :integer | :boolean | :array | :object
  #
  # This function, ensures that if the map has the key — it'll convert the corresponding value
  # to an atom.
  defp convert_value_to_atom_if_present(map, key) do
    update_fn = fn
      nil -> nil
      s -> String.to_atom(s)
    end

    update_map_if_key_present(map, key, update_fn)
  end

  # In some cases, e.g. Schema type we must convert values that are list of strings to a list atoms,
  #
  # This function, ensures that if the map has the key — it'll convert the corresponding value
  # to a list of atoms.
  defp convert_value_to_list_of_atoms_if_present(map, key) do
    map_fn = &String.to_atom/1
    update_map_if_key_present(map, key, &Enum.map(&1, map_fn))
  end

  # The Schema.type and Schema.required keys require some special treatment since their
  # values should be converted to atoms
  defp prepare_schema(map) do
    map
    |> convert_value_to_atom_if_present("type")
    |> convert_value_to_atom_if_present("format")
    |> convert_value_to_atom_if_present("x-struct")
    |> convert_value_to_list_of_atoms_if_present("required")
  end

  defp to_struct(nil, _mod), do: nil

  defp to_struct(tag, Tag) when is_binary(tag), do: tag

  defp to_struct(map, Tag) when is_map(map) do
    Tag
    |> struct_from_map(map)
    |> prop_to_struct(:externalDocs, ExternalDocumentation)
    |> add_extensions(map)
  end

  defp to_struct(list, Tag) when is_list(list) do
    list
    |> Enum.map(&to_struct(&1, Tag))
  end

  defp to_struct(map, Components) do
    Components
    |> struct_from_map(map)
    |> prop_to_struct(:schemas, Schemas)
    |> prop_to_struct(:responses, Responses)
    |> prop_to_struct(:parameters, Parameters)
    |> prop_to_struct(:examples, Examples)
    |> prop_to_struct(:requestBodies, RequestBodies)
    |> prop_to_struct(:headers, Headers)
    |> prop_to_struct(:securitySchemes, SecuritySchemes)
    |> prop_to_struct(:links, Links)
    |> prop_to_struct(:callbacks, Callbacks)
    |> add_extensions(map)
  end

  defp to_struct(map, Link) do
    Link
    |> struct_from_map(map)
    |> prop_to_struct(:server, Server)
    |> prop_to_struct(:requestBody, RequestBody)
    |> prop_to_struct(:parameters, Parameters)
    |> add_extensions(map)
  end

  defp to_struct(map, Links), do: embedded_ref_or_struct(map, Link)

  defp to_struct(map, SecurityScheme) do
    SecurityScheme
    |> struct_from_map(map)
    |> prop_to_struct(:flows, OAuthFlows)
    |> add_extensions(map)
  end

  defp to_struct(map, SecuritySchemes), do: embedded_ref_or_struct(map, SecurityScheme)

  defp to_struct(map, OAuthFlow) do
    OAuthFlow
    |> struct_from_map(map)
    |> add_extensions(map)
  end

  defp to_struct(map, OAuthFlows) do
    OAuthFlows
    |> struct_from_map(map)
    |> prop_to_struct(:implicit, OAuthFlow)
    |> prop_to_struct(:password, OAuthFlow)
    |> prop_to_struct(:clientCredentials, OAuthFlow)
    |> prop_to_struct(:authorizationCode, OAuthFlow)
    |> add_extensions(map)
  end

  defp to_struct(%{"$ref" => _} = map, Schema), do: struct_from_map(Reference, map)

  defp to_struct(%{"type" => type} = map, Schema)
       when type in ~w(number integer boolean string) do
    map
    |> prepare_schema()
    |> (&struct_from_map(Schema, &1)).()
    |> prop_to_struct(:xml, Xml)
    |> add_extensions(map)
  end

  defp to_struct(%{"type" => "array"} = map, Schema) do
    map
    |> prepare_schema()
    |> (&struct_from_map(Schema, &1)).()
    |> prop_to_struct(:items, Schema)
    |> prop_to_struct(:xml, Xml)
    |> add_extensions(map)
  end

  defp to_struct(%{"anyOf" => _valid_schemas} = map, Schema) do
    Schema
    |> struct_from_map(prepare_schema(map))
    |> prop_to_struct(:anyOf, Schemas)
    |> prop_to_struct(:discriminator, Discriminator)
    |> add_extensions(map)
  end

  defp to_struct(%{"oneOf" => _valid_schemas} = map, Schema) do
    Schema
    |> struct_from_map(prepare_schema(map))
    |> prop_to_struct(:oneOf, Schemas)
    |> prop_to_struct(:discriminator, Discriminator)
    |> add_extensions(map)
  end

  defp to_struct(%{"allOf" => _valid_schemas} = map, Schema) do
    Schema
    |> struct_from_map(prepare_schema(map))
    |> prop_to_struct(:allOf, Schemas)
    |> prop_to_struct(:discriminator, Discriminator)
    |> add_extensions(map)
  end

  defp to_struct(%{"type" => "object"} = map, Schema) do
    map
    |> Map.update("properties", %{}, fn v ->
      v
      |> Map.new(fn {k, v} ->
        {String.to_atom(k), v}
      end)
    end)
    |> prepare_schema()
    |> (&struct_from_map(Schema, &1)).()
    |> prop_to_struct(:properties, Schemas)
    |> manage_additional_properties()
    |> prop_to_struct(:externalDocs, ExternalDocumentation)
    |> add_extensions(map)
  end

  defp to_struct(%{"not" => _valid_schemas} = map, Schema) do
    Schema
    |> struct_from_map(map)
    |> prop_to_struct(:not, Schema)
    |> add_extensions(map)
  end

  defp to_struct(map, Schemas) when is_map(map), do: embedded_ref_or_struct(map, Schema)
  defp to_struct(list, Schemas) when is_list(list), do: embedded_ref_or_struct(list, Schema)

  defp to_struct(map, Callback) do
    map
    |> Map.new(fn {k, v} ->
      {k, to_struct(v, PathItem)}
    end)
  end

  defp to_struct(map_or_list, Callbacks), do: embedded_ref_or_struct(map_or_list, Callback)

  defp to_struct(map, Operation) do
    Operation
    |> struct_from_map(map)
    |> prop_to_struct(:tags, Tag)
    |> prop_to_struct(:externalDocs, ExternalDocumentation)
    |> prop_to_struct(:responses, Responses)
    |> prop_to_struct(:parameters, Parameters)
    |> prop_to_struct(:requestBody, RequestBody)
    |> prop_to_struct(:callbacks, Callbacks)
    |> prop_to_struct(:servers, Servers)
    |> add_extensions(map)
  end

  defp to_struct(%{"$ref" => _} = map, RequestBody), do: struct_from_map(Reference, map)

  defp to_struct(map, RequestBody) do
    RequestBody
    |> struct_from_map(map)
    |> prop_to_struct(:content, Content)
    |> add_extensions(map)
  end

  defp to_struct(map, RequestBodies), do: embedded_ref_or_struct(map, RequestBody)

  defp to_struct(map, Parameter) do
    map
    |> convert_value_to_atom_if_present("name")
    |> convert_value_to_atom_if_present("in")
    |> convert_value_to_atom_if_present("style")
    |> (&struct_from_map(Parameter, &1)).()
    |> prop_to_struct(:examples, Examples)
    |> prop_to_struct(:content, Content)
    |> prop_to_struct(:schema, Schema)
    |> add_extensions(map)
  end

  defp to_struct(map_or_list, Parameters), do: embedded_ref_or_struct(map_or_list, Parameter)

  defp to_struct(map, ServerVariable) do
    ServerVariable
    |> struct_from_map(map)
    |> add_extensions(map)
  end

  defp to_struct(map, ServerVariables) do
    map
    |> Map.new(fn {k, v} ->
      {k, to_struct(v, ServerVariable)}
    end)
  end

  defp to_struct(map, Server) do
    Server
    |> struct_from_map(map)
    |> prop_to_struct(:variables, ServerVariables)
    |> add_extensions(map)
  end

  defp to_struct(list, Servers) when is_list(list) do
    Enum.map(list, &to_struct(&1, Server))
  end

  defp to_struct(map, Response) do
    Response
    |> struct_from_map(map)
    |> prop_to_struct(:headers, Headers)
    |> prop_to_struct(:content, Content)
    |> prop_to_struct(:links, Links)
    |> add_extensions(map)
  end

  defp to_struct(map, Responses), do: embedded_ref_or_struct(map, Response)

  defp to_struct(map, MediaType) do
    MediaType
    |> struct_from_map(map)
    |> prop_to_struct(:examples, Examples)
    |> prop_to_struct(:encoding, Encoding)
    |> prop_to_struct(:schema, Schema)
    |> add_extensions(map)
  end

  defp to_struct(map, Content) do
    map
    |> Map.new(fn {k, v} ->
      {k, to_struct(v, MediaType)}
    end)
  end

  defp to_struct(map, Encoding) do
    map
    |> Map.new(fn {k, v} ->
      {k,
       Encoding
       |> struct_from_map(v)
       |> convert_value_to_atom_if_present(:style)
       |> prop_to_struct(:headers, Headers)
       |> add_extensions(v)}
    end)
  end

  defp to_struct(map, Example), do: Example |> struct_from_map(map) |> add_extensions(map)
  defp to_struct(map_or_list, Examples), do: embedded_ref_or_struct(map_or_list, Example)

  defp to_struct(map, Header) do
    Header
    |> struct_from_map(map)
    |> prop_to_struct(:schema, Schema)
    |> add_extensions(map)
  end

  defp to_struct(map, Headers), do: embedded_ref_or_struct(map, Header)

  defp to_struct(map, PathItem) do
    PathItem
    |> struct_from_map(map)
    |> prop_to_struct(:delete, Operation)
    |> prop_to_struct(:get, Operation)
    |> prop_to_struct(:head, Operation)
    |> prop_to_struct(:options, Operation)
    |> prop_to_struct(:patch, Operation)
    |> prop_to_struct(:post, Operation)
    |> prop_to_struct(:put, Operation)
    |> prop_to_struct(:trace, Operation)
    |> prop_to_struct(:parameters, Parameters)
    |> prop_to_struct(:servers, Servers)
    |> add_extensions(map)
  end

  defp to_struct(map, PathItems) do
    map
    |> Map.new(fn {k, v} ->
      {k, to_struct(v, PathItem)}
    end)
  end

  defp to_struct(map, Info) do
    Info
    |> struct_from_map(map)
    |> prop_to_struct(:contact, Contact)
    |> prop_to_struct(:license, License)
    |> add_extensions(map)
  end

  defp to_struct(map, mod)
       when mod in [License, Contact, ExternalDocumentation, Discriminator, Xml],
       do: mod |> struct_from_map(map) |> add_extensions(map)

  defp to_struct(list, mod) when is_list(list) and is_atom(mod),
    do: Enum.map(list, &to_struct(&1, mod))

  defp to_struct(map, module) when is_map(map) and is_atom(module),
    do: struct_from_map(module, map)

  defp prop_to_struct(map, key, mod) when is_map(map) and is_atom(key) and is_atom(mod) do
    Map.update!(map, key, fn v ->
      to_struct(v, mod)
    end)
  end

  # additionalProperties is a reference
  defp manage_additional_properties(%_{additionalProperties: %{"$ref" => reference}} = map) do
    Map.put(map, :additionalProperties, %Reference{"$ref": reference})
  end

  # additionalProperties is a boolean without validation
  defp manage_additional_properties(%_{additionalProperties: value} = map) when is_boolean(value),
    do: map

  # additionalProperties with custom one off validation
  defp manage_additional_properties(%_{additionalProperties: %{} = props} = map) do
    Map.put(map, :additionalProperties, to_struct(props, Schema))
  end

  defp manage_additional_properties(map), do: map

  defp add_extensions(struct, map) do
    extensions =
      map
      |> Enum.filter(fn {key, _val} ->
        String.starts_with?(key, "x-") and key not in @open_api_spex_extensions
      end)
      |> Map.new()

    Map.put(struct, :extensions, if(map_size(extensions) == 0, do: nil, else: extensions))
  end
end
