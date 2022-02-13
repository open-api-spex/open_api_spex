defmodule OpenApiSpex.DeprecatedCast do
  @moduledoc """
  This module is deprecated.

  Please use `OpenApiSpex.Cast` instead.
  """

  alias OpenApiSpex.{Discriminator, Reference, Schema}

  def cast(%Schema{type: :boolean}, value, _schemas) when is_boolean(value), do: {:ok, value}

  def cast(%Schema{type: :boolean}, value, _schemas) when is_binary(value) do
    case value do
      "true" -> {:ok, true}
      "false" -> {:ok, false}
      _ -> {:error, "Invalid boolean: #{inspect(value)}"}
    end
  end

  def cast(%Schema{type: :integer}, value, _schemas) when is_integer(value), do: {:ok, value}

  def cast(%Schema{type: :integer}, value, _schemas) when is_binary(value) do
    case Integer.parse(value) do
      {i, ""} -> {:ok, i}
      _ -> {:error, :bad_integer}
    end
  end

  def cast(%Schema{type: :number}, value, _schemas) when is_float(value), do: {:ok, value}

  def cast(%Schema{type: :number}, value, _schemas) when is_integer(value), do: {:ok, value / 1}

  def cast(%Schema{type: :number}, value, _schemas) when is_binary(value) do
    case Float.parse(value) do
      {x, ""} -> {:ok, x}
      _ -> {:error, :bad_float}
    end
  end

  def cast(%Schema{type: :string, format: :"date-time"}, value, _schemas) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, date_time = %DateTime{}, _offset} -> {:ok, date_time}
      error = {:error, _reason} -> error
    end
  end

  def cast(%Schema{type: :string, format: :date}, value, _schemas) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date = %Date{}} -> {:ok, date}
      error = {:error, _reason} -> error
    end
  end

  def cast(%Schema{type: :string, format: :binary}, %Plug.Upload{} = value, _schemas) do
    {:ok, value}
  end

  def cast(%Schema{type: :string}, value, _schemas) when is_binary(value), do: {:ok, value}

  def cast(%Schema{type: :array, items: nil}, value, _schemas) when is_list(value),
    do: {:ok, value}

  def cast(%Schema{type: :array}, [], _schemas), do: {:ok, []}

  def cast(schema = %Schema{type: :array, items: items_schema}, [x | rest], schemas) do
    with {:ok, x_cast} <- cast(items_schema, x, schemas),
         {:ok, rest_cast} <- cast(schema, rest, schemas) do
      {:ok, [x_cast | rest_cast]}
    end
  end

  def cast(%Schema{type: :array}, value, _schemas) when not is_list(value) do
    {:error, "Invalid array: #{inspect(value)}"}
  end

  def cast(
        schema = %Schema{type: :object, discriminator: discriminator = %{}},
        value = %{},
        schemas
      ) do
    discriminator_property = String.to_existing_atom(discriminator.propertyName)

    already_cast? =
      if Map.has_key?(value, discriminator_property) do
        {:error, :already_cast}
      else
        :ok
      end

    with :ok <- already_cast?,
         {:ok, partial_cast} <-
           cast(%Schema{type: :object, properties: schema.properties}, value, schemas),
         {:ok, derived_schema} <- Discriminator.resolve(discriminator, value, schemas),
         {:ok, result} <- cast(derived_schema, partial_cast, schemas),
         {:ok, struct} <- make_struct(result, derived_schema) do
      {:ok, struct}
    else
      {:error, :already_cast} -> {:ok, value}
      {:error, reason} -> {:error, reason}
    end
  end

  def cast(schema = %Schema{type: :object, allOf: all_of}, value = %{}, schemas)
      when is_list(all_of),
      do: OpenApiSpex.Cast.cast(schema, value, schemas)

  def cast(schema = %Schema{type: :object, allOf: []}, value = %{}, schemas) do
    cast(%{schema | allOf: nil}, value, schemas)
  end

  def cast(schema = %Schema{oneOf: one_of}, value, schemas)
      when is_list(one_of),
      do: OpenApiSpex.Cast.cast(schema, value, schemas)

  def cast(%Schema{oneOf: []}, _value, _schemas) do
    {:error, "Failed to cast to any schema in oneOf"}
  end

  def cast(schema = %Schema{anyOf: [first | rest]}, value, schemas) do
    case cast(first, value, schemas) do
      {:ok, result} ->
        cast(%{schema | anyOf: nil}, result, schemas)

      {:error, _reason} ->
        cast(%{schema | anyOf: rest}, value, schemas)
    end
  end

  def cast(%Schema{anyOf: []}, _value, _schemas) do
    {:error, "Failed to cast to any schema in anyOf"}
  end

  def cast(schema = %Schema{type: :object}, value, schemas) when is_map(value) do
    schema = %{schema | properties: schema.properties || %{}}

    {regular_properties, others} =
      value
      |> no_struct()
      |> Enum.split_with(fn {k, _v} -> is_binary(k) end)

    with {:ok, props} <- cast_properties(schema, regular_properties, schemas) do
      make_struct(Map.new(others ++ props), schema)
    end
  end

  def cast(ref = %Reference{}, val, schemas),
    do: cast(Reference.resolve_schema(ref, schemas), val, schemas)

  def cast(_additional_properties = false, val, _schemas) do
    {:error, "Unexpected field with value #{inspect(val)}"}
  end

  def cast(_additional_properties, val, _schemas), do: {:ok, val}

  defp make_struct(val = %_{}, _), do: {:ok, val}
  defp make_struct(val, %{"x-struct": nil}), do: {:ok, val}

  defp make_struct(val, %{"x-struct": mod}) do
    keys = mod.schema |> OpenApiSpex.Schema.properties() |> Keyword.keys()

    if Map.keys(val) -- keys == [] do
      {:ok, struct(mod, val)}
    else
      {:error, :bad_structure}
    end
  end

  defp no_struct(val), do: Map.delete(val, :__struct__)

  @spec cast_properties(Schema.t(), list, %{String.t() => Schema.t()}) ::
          {:ok, list} | {:error, String.t()}
  defp cast_properties(%Schema{}, [], _schemas), do: {:ok, []}

  defp cast_properties(object_schema = %Schema{}, [{key, value} | rest], schemas) do
    {name, schema} =
      Enum.find(
        object_schema.properties,
        {key, object_schema.additionalProperties},
        fn {name, _schema} -> to_string(name) == to_string(key) end
      )

    with {:ok, new_value} <- cast(schema, value, schemas),
         {:ok, cast_tail} <- cast_properties(object_schema, rest, schemas) do
      {:ok, [{name, new_value} | cast_tail]}
    end
  end

  def validate(schema, val, schemas), do: validate(schema, val, "#", schemas)

  @spec validate(Schema.t() | Reference.t(), any, String.t(), %{
          String.t() => Schema.t() | Reference.t()
        }) :: :ok | {:error, String.t()}
  def validate(ref = %Reference{}, val, path, schemas),
    do: validate(Reference.resolve_schema(ref, schemas), val, path, schemas)

  def validate(%Schema{nullable: true}, nil, _path, _schemas), do: :ok

  def validate(%Schema{type: type}, nil, path, _schemas) when not is_nil(type) do
    {:error, "#{path}: null value where #{type} expected"}
  end

  def validate(schema = %Schema{anyOf: valid_schemas}, value, path, schemas)
      when is_list(valid_schemas) do
    if Enum.any?(valid_schemas, &(validate(&1, value, path, schemas) == :ok)) do
      validate(%{schema | anyOf: nil}, value, path, schemas)
    else
      {:error, "#{path}: Failed to validate against any schema"}
    end
  end

  def validate(schema = %Schema{oneOf: valid_schemas}, value, path, schemas)
      when is_list(valid_schemas) do
    case Enum.count(valid_schemas, &(validate(&1, value, path, schemas) == :ok)) do
      1 -> validate(%{schema | oneOf: nil}, value, path, schemas)
      0 -> {:error, "#{path}: Failed to validate against any schema"}
      other -> {:error, "#{path}: Validated against #{other} schemas when only one expected"}
    end
  end

  def validate(schema = %Schema{allOf: required_schemas}, value, path, schemas)
      when is_list(required_schemas) do
    required_schemas
    |> Enum.map(&validate(&1, value, path, schemas))
    |> Enum.reject(&(&1 == :ok))
    |> Enum.map(fn {:error, msg} -> msg end)
    |> case do
      [] -> validate(%{schema | allOf: nil}, value, path, schemas)
      errors -> {:error, Enum.join(errors, "\n")}
    end
  end

  def validate(schema = %Schema{not: not_schema}, value, path, schemas)
      when not is_nil(not_schema) do
    case validate(not_schema, value, path, schemas) do
      {:error, _} -> validate(%{schema | not: nil}, value, path, schemas)
      :ok -> {:error, "#{path}: Value is valid for schema given in `not`"}
    end
  end

  def validate(%Schema{enum: options = [_ | _]}, value, path, _schemas) do
    case Enum.member?(options, value) do
      true ->
        :ok

      _ ->
        {:error, "#{path}: Value not in enum: #{inspect(value)}"}
    end
  end

  def validate(schema = %Schema{type: :integer}, value, path, _schemas) when is_integer(value) do
    validate_number_types(schema, value, path)
  end

  def validate(schema = %Schema{type: :number}, value, path, _schemas) when is_number(value) do
    validate_number_types(schema, value, path)
  end

  def validate(schema = %Schema{type: :string}, value, path, _schemas) when is_binary(value) do
    validate_string_types(schema, value, path)
  end

  def validate(%Schema{type: :string, format: :"date-time"}, %DateTime{}, _path, _schemas) do
    :ok
  end

  def validate(%Schema{type: :string, format: :binary}, %Plug.Upload{}, _path, _schemas) do
    :ok
  end

  def validate(%Schema{type: expected_type}, %DateTime{}, path, _schemas) do
    {:error, "#{path}: invalid type DateTime where #{expected_type} expected"}
  end

  def validate(%Schema{type: :string, format: :date}, %Date{}, _path, _schemas) do
    :ok
  end

  def validate(%Schema{type: expected_type}, %Date{}, path, _schemas) do
    {:error, "#{path}: invalid type Date where #{expected_type} expected"}
  end

  def validate(%Schema{type: :boolean}, value, _path, _schemas) when is_boolean(value), do: :ok

  def validate(schema = %Schema{type: :array}, value, path, schemas) when is_list(value) do
    with :ok <- validate_max_items(schema, value, path),
         :ok <- validate_min_items(schema, value, path),
         :ok <- validate_unique_items(schema, value, path) do
      validate_array_items(schema, value, {path, 0}, schemas)
    end
  end

  def validate(schema = %Schema{type: :object}, value = %{}, path, schemas) do
    schema = %{schema | properties: schema.properties || %{}, required: schema.required || []}

    with :ok <- validate_required_properties(schema, value, path),
         :ok <- validate_max_properties(schema, value, path),
         :ok <- validate_min_properties(schema, value, path) do
      validate_object_properties(
        schema.properties,
        MapSet.new(schema.required),
        value,
        path,
        schemas
      )
    end
  end

  def validate(%Schema{type: nil}, _value, _path, _schemas) do
    # polymorphic schemas will terminate here after validating against anyOf/oneOf/allOf/not
    :ok
  end

  def validate(%Schema{type: expected_type}, value, path, _schemas)
      when not is_nil(expected_type) do
    {:error, "#{path}: invalid type #{term_type(value)} where #{expected_type} expected"}
  end

  @spec term_type(term) :: Schema.data_type() | nil | String.t()
  defp term_type(v) when is_list(v), do: :array
  defp term_type(v) when is_map(v), do: :object
  defp term_type(v) when is_binary(v), do: :string
  defp term_type(v) when is_boolean(v), do: :boolean
  defp term_type(v) when is_integer(v), do: :integer
  defp term_type(v) when is_number(v), do: :number
  defp term_type(v) when is_nil(v), do: nil
  defp term_type(v), do: inspect(v)

  @spec validate_number_types(Schema.t(), number, String.t()) :: :ok | {:error, String.t()}
  defp validate_number_types(schema, value, path) do
    with :ok <- validate_multiple(schema, value, path),
         :ok <- validate_maximum(schema, value, path) do
      validate_minimum(schema, value, path)
    end
  end

  @spec validate_string_types(Schema.t(), String.t(), String.t()) :: :ok | {:error, String.t()}
  defp validate_string_types(schema, value, path) do
    with :ok <- validate_max_length(schema, value, path),
         :ok <- validate_min_length(schema, value, path) do
      validate_pattern(schema, value, path)
    end
  end

  @spec validate_multiple(Schema.t(), number, String.t()) :: :ok | {:error, String.t()}
  defp validate_multiple(%{multipleOf: nil}, _, _), do: :ok
  defp validate_multiple(%{multipleOf: n}, value, _) when round(value / n) * n == value, do: :ok

  defp validate_multiple(%{multipleOf: n}, value, path),
    do: {:error, "#{path}: #{value} is not a multiple of #{n}"}

  @spec validate_maximum(Schema.t(), number, String.t()) :: :ok | {:error, String.t()}
  defp validate_maximum(%{maximum: nil}, _val, _path), do: :ok

  defp validate_maximum(%{maximum: n, exclusiveMaximum: true}, value, _path) when value < n,
    do: :ok

  defp validate_maximum(%{maximum: n, exclusiveMaximum: true}, value, path),
    do: {:error, "#{path}: #{value} is larger than the exclusive maximum #{n}"}

  defp validate_maximum(%{maximum: n}, value, _path) when value <= n, do: :ok

  defp validate_maximum(%{maximum: n}, value, path),
    do: {:error, "#{path}: #{value} is larger than maximum #{n}"}

  @spec validate_minimum(Schema.t(), number, String.t()) :: :ok | {:error, String.t()}
  defp validate_minimum(%{minimum: nil}, _val, _path), do: :ok

  defp validate_minimum(%{minimum: n, exclusiveMinimum: true}, value, _path) when value > n,
    do: :ok

  defp validate_minimum(%{minimum: n, exclusiveMinimum: true}, value, path),
    do: {:error, "#{path}: #{value} is smaller than the exclusive minimum #{n}"}

  defp validate_minimum(%{minimum: n}, value, _path) when value >= n, do: :ok

  defp validate_minimum(%{minimum: n}, value, path),
    do: {:error, "#{path}: #{value} is smaller than minimum #{n}"}

  @spec validate_max_length(Schema.t(), String.t(), String.t()) :: :ok | {:error, String.t()}
  defp validate_max_length(%{maxLength: nil}, _val, _path), do: :ok

  defp validate_max_length(%{maxLength: n}, value, path) do
    case String.length(value) <= n do
      true -> :ok
      _ -> {:error, "#{path}: String length is larger than maxLength: #{n}"}
    end
  end

  @spec validate_min_length(Schema.t(), String.t(), String.t()) :: :ok | {:error, String.t()}
  defp validate_min_length(%{minLength: nil}, _val, _path), do: :ok

  defp validate_min_length(%{minLength: n}, value, path) do
    case String.length(value) >= n do
      true -> :ok
      _ -> {:error, "#{path}: String length is smaller than minLength: #{n}"}
    end
  end

  @spec validate_pattern(Schema.t(), String.t(), String.t()) :: :ok | {:error, String.t()}
  defp validate_pattern(%{pattern: nil}, _val, _path), do: :ok

  defp validate_pattern(schema = %{pattern: regex}, val, path) when is_binary(regex) do
    with {:ok, regex} <- Regex.compile(regex) do
      validate_pattern(%{schema | pattern: regex}, val, path)
    end
  end

  defp validate_pattern(%{pattern: regex = %Regex{}}, val, path) do
    case Regex.match?(regex, val) do
      true -> :ok
      _ -> {:error, "#{path}: Value #{inspect(val)} does not match pattern: #{regex.source}"}
    end
  end

  @spec validate_max_items(Schema.t(), list, String.t()) :: :ok | {:error, String.t()}
  defp validate_max_items(%Schema{maxItems: nil}, _val, _path), do: :ok
  defp validate_max_items(%Schema{maxItems: n}, value, _path) when length(value) <= n, do: :ok

  defp validate_max_items(%Schema{maxItems: n}, value, path) do
    {:error, "#{path}: Array length #{length(value)} is larger than maxItems: #{n}"}
  end

  @spec validate_min_items(Schema.t(), list, String.t()) :: :ok | {:error, String.t()}
  defp validate_min_items(%Schema{minItems: nil}, _val, _path), do: :ok
  defp validate_min_items(%Schema{minItems: n}, value, _path) when length(value) >= n, do: :ok

  defp validate_min_items(%Schema{minItems: n}, value, path) do
    {:error, "#{path}: Array length #{length(value)} is smaller than minItems: #{n}"}
  end

  @spec validate_unique_items(Schema.t(), list, String.t()) :: :ok | {:error, String.t()}
  defp validate_unique_items(%Schema{uniqueItems: true}, value, path) do
    unique_size =
      value
      |> MapSet.new()
      |> MapSet.size()

    case unique_size == length(value) do
      true -> :ok
      _ -> {:error, "#{path}: Array items must be unique"}
    end
  end

  defp validate_unique_items(_schema, _value, _path), do: :ok

  @spec validate_array_items(Schema.t(), list, {String.t(), integer}, %{String.t() => Schema.t()}) ::
          :ok | {:error, String.t()}
  defp validate_array_items(%Schema{type: :array, items: nil}, value, _path, _schemas)
       when is_list(value),
       do: :ok

  defp validate_array_items(%Schema{type: :array}, [], _path, _schemas), do: :ok

  defp validate_array_items(
         schema = %Schema{type: :array, items: item_schema},
         [x | rest],
         {path, index},
         schemas
       ) do
    with :ok <- validate(item_schema, x, "#{path}/#{index}", schemas) do
      validate_array_items(schema, rest, {path, index + 1}, schemas)
    end
  end

  @spec validate_required_properties(Schema.t(), %{}, String.t()) :: :ok | {:error, String.t()}
  defp validate_required_properties(%Schema{type: :object, required: nil}, _val, _path), do: :ok

  defp validate_required_properties(%Schema{type: :object, required: required}, value = %{}, path) do
    missing = required -- Map.keys(value)

    case missing do
      [] -> :ok
      _ -> {:error, "#{path}: Missing required properties: #{inspect(missing)}"}
    end
  end

  @spec validate_max_properties(Schema.t(), %{}, String.t()) :: :ok | {:error, String.t()}
  defp validate_max_properties(%Schema{type: :object, maxProperties: nil}, _val, _path), do: :ok

  defp validate_max_properties(%Schema{type: :object, maxProperties: n}, val, _path)
       when map_size(val) <= n,
       do: :ok

  defp validate_max_properties(%Schema{type: :object, maxProperties: n}, val, path) do
    {:error, "#{path}: Object property count #{map_size(val)} is greater than maxProperties: #{n}"}
  end

  @spec validate_min_properties(Schema.t(), %{}, String.t()) :: :ok | {:error, String.t()}
  defp validate_min_properties(%Schema{type: :object, minProperties: nil}, _val, _path), do: :ok

  defp validate_min_properties(%Schema{type: :object, minProperties: n}, val, _path)
       when map_size(val) >= n,
       do: :ok

  defp validate_min_properties(%Schema{type: :object, minProperties: n}, val, path) do
    {:error, "#{path}: Object property count #{map_size(val)} is less than minProperties: #{n}"}
  end

  @spec validate_object_properties(Enumerable.t(), MapSet.t(), %{}, String.t(), %{
          String.t() => Schema.t() | Reference.t()
        }) :: :ok | {:error, String.t()}
  defp validate_object_properties(properties = %{}, required, value = %{}, path, schemas = %{}) do
    properties
    |> Enum.filter(fn {name, _schema} -> Map.has_key?(value, name) end)
    |> validate_object_properties(required, value, path, schemas)
  end

  defp validate_object_properties([], _required, _val, _path, _schemas), do: :ok

  defp validate_object_properties(
         [{name, schema} | rest],
         required,
         value = %{},
         path,
         schemas = %{}
       ) do
    property_required = MapSet.member?(required, name)
    property_value = Map.get(value, name)
    property_path = "#{path}/#{name}"

    with :ok <-
           validate_object_property(
             schema,
             property_required,
             property_value,
             property_path,
             schemas
           ) do
      validate_object_properties(rest, required, value, path, schemas)
    end
  end

  defp validate_object_property(_schema, false, nil, _path, _schemas), do: :ok

  defp validate_object_property(schema, _required, value, path, schemas) do
    validate(schema, value, path, schemas)
  end
end
