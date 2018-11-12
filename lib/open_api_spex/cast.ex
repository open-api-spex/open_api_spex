defmodule OpenApiSpex.Cast do
  @moduledoc false
  alias OpenApiSpex.{Error, Discriminator, Reference, Schema, Validation}

  @doc """
  Like cast/3, except the cast error is just a string.
  """
  def simple_cast(value, schema, %{} = schemas) do
    case cast(value, schema, schemas) do
      {:ok, value} -> {:ok, value}
      {:error, %{errors: [error | _]}} -> {:error, Error.message(error)}
    end
  end

  def cast(value, schema, %{} = schemas \\ %{}) do
    cast(%Validation{value: value, schema: schema, schemas: schemas})
  end

  def cast(%Validation{schema: %{nullable: true}, value: nil}) do
    {:ok, nil}
  end

  def cast(%Validation{schema: %{type: :boolean}, value: value}) when is_boolean(value) do
    {:ok, value}
  end

  def cast(%Validation{schema: %{type: :boolean}, value: value} = validation)
      when is_binary(value) do
    case value do
      "true" -> {:ok, true}
      "false" -> {:ok, false}
      _ -> {:error, %{validation | errors: [Error.new(:invalid_type, :boolean, value)]}}
    end
  end

  def cast(%Validation{schema: %{type: :boolean}, value: value} = validation) do
    {:error, %{validation | errors: [Error.new(:invalid_type, :boolean, value)]}}
  end

  def cast(%Validation{schema: %{type: :integer}, value: value}) when is_integer(value) do
    {:ok, value}
  end

  def cast(%Validation{schema: %{type: :integer}, value: value} = validation)
      when is_binary(value) do
    case Integer.parse(value) do
      {int_value, ""} -> {:ok, int_value}
      _ ->
        error = Error.new(:invalid_type, :integer, value)
        error = %{error | path: validation.path}
        {:error, %{validation | errors: [error]}}
    end
  end

  def cast(%Validation{schema: %{type: :integer}, value: value} = validation) do
    {:error, %{validation | errors: [Error.new(:invalid_type, :integer, value)]}}
  end

  def cast(%Validation{schema: %{type: :number, format: fmt}, value: value})
      when is_integer(value) and fmt in [:float, :double] do
    {:ok, value * 1.0}
  end

  def cast(%Validation{schema: %{type: :number}, value: value}) when is_number(value) do
    {:ok, value}
  end

  def cast(%Validation{schema: %{type: :number}, value: value} = validation)
      when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> {:ok, number}
      _ -> {:error, %{validation | errors: [Error.new(:invalid_type, :number, value)]}}
    end
  end

  def cast(%Validation{schema: %{type: :number}, value: value} = validation) do
    {:error, %{validation | errors: [Error.new(:invalid_type, :number, value)]}}
  end

  def cast(%Validation{schema: %{type: :string, format: :"date-time"}, value: value} = validation)
      when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime = %DateTime{}, _offset} -> {:ok, datetime}
      {:error, _reason} -> {:error, %{validation | errors: [Error.new(:invalid_format, :"date-time", value)]}}
    end
  end

  def cast(%Validation{schema: %{type: :string, format: :date}, value: value} = validation)
      when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date = %Date{}} -> {:ok, date}
      {:error, _} -> {:error, %{validation | errors: [Error.new(:invalid_format, :date, value)]}}
    end
  end

  def cast(%Validation{schema: %{type: :string}, value: value}) when is_binary(value) do
    {:ok, value}
  end

  def cast(%Validation{schema: %{type: :string}, value: value} = validation) do
    {:error, %{validation | errors: [Error.new(:invalid_type, :string, value)]}}
  end

  def cast(%Validation{schema: %{type: :array, items: nil}, value: value}) when is_list(value) do
    {:ok, value}
  end

  def cast(%Validation{schema: %{type: :array}, value: items} = validation) when is_list(items) do
    results =
      items
      |> Enum.with_index()
      |> Enum.map(fn {item, index} ->
        case cast(%{validation | schema: validation.schema.items, value: item, errors: []}) do
          {:ok, cast_item} -> {:ok, cast_item}
          {:error, error_validation} -> {:error, add_to_error_paths(error_validation.errors, index)}
        end
      end)

    {cast_items, errors} = Enum.split_with(results, &match?({:ok, _cast_item}, &1))
    cast_items = Enum.map(cast_items, &elem(&1, 1))
    errors = errors |> Enum.map(&elem(&1, 1)) |> Enum.concat()

    case errors do
      [] -> {:ok, cast_items}
      _ -> {:error, %{validation | errors: errors ++ validation.errors}}
    end
  end

  def cast(%Validation{schema: %{type: :array}, value: value} = validation) when not is_list(value) do
    {:error, %{validation | errors: [Error.new(:invalid_type, :array, value: value) | validation.errors]}}
  end

  def cast(%Validation{schema: %{type: :object}, value: value} = validation)
      when not is_map(value) do
    {:error, %{validation | errors: [Error.new(:invalid_type, :object, value)]}}
  end

  def cast(
        %Validation{
          schema: %{type: :object, discriminator: %{} = discriminator} = schema,
          value: %{} = value
        } = validator
      ) do
    discriminator_property = String.to_existing_atom(discriminator.propertyName)

    already_cast = if Map.has_key?(value, discriminator_property) do
        {:error, :already_cast}
      else
        false
      end

    with false <- already_cast,
         {:ok, partial_cast} <-
           cast(%{
             validator
             | schema: %Schema{type: :object, properties: schema.properties},
               value: value
           }),
         {:ok, validator_1} <- discriminate(validator, discriminator),
         {:ok, value} <- cast(%{validator_1 | value: partial_cast}) do
      {:ok, make_struct(value, schema)}
    else
      {:error, :already_cast} -> {:ok, value}
      {:error, validator} -> {:error, validator}
    end
  end

  def cast(%Validation{schema: %{type: :object, allOf: [first | rest]}, value: %{}} = validation) do
    schema = validation.schema

    with {:ok, value} <- cast(%{validation | schema: first}),
         {:ok, value} <- cast(%{validation | value: value, schema: %{schema | allOf: rest}}) do
      {:ok, value}
    end
  end

  def cast(
        %Validation{schema: schema = %Schema{type: :object, allOf: []}, value: value = %{}} =
          validation
      ) do
    cast(%{validation | schema: %{schema | allOf: nil}, value: value})
  end

  def cast(
        %Validation{schema: %{oneOf: [first | rest]} = schema, value: value, schemas: schemas} =
          validation
      ) do
    case cast(%Validation{schema: first, value: value, schemas: schemas}) do
      {:ok, value} ->
        cast(%Validation{schema: %{schema | oneOf: nil}, value: value, schemas: schemas})

      {:error, _} ->
        cast(%{validation | schema: %{schema | oneOf: rest}})
    end
  end

  def cast(%Validation{schema: %{oneOf: []}, value: value} = validation) do
    {:error, %{validation | errors: [Error.new(:polymorphic_failed, value, :oneOf)]}}
  end

  def cast(%Validation{schema: schema = %Schema{anyOf: [first | rest]}} = validation) do
    case cast(%{validation | schema: first}) do
      {:ok, result} ->
        cast(%{validation | schema: %{schema | anyOf: nil}, value: result})

      {:error, _} ->
        cast(%{validation | schema: %{schema | anyOf: rest}})
    end
  end

  def cast(%Validation{schema: %{anyOf: []}, value: value} = validation) do
    {:error, %{validation | errors: [Error.new(:polymorphic_failed, value, :anyOf)]}}
  end

  def cast(
        %Validation{schema: schema = %Schema{type: :object}, value: value, schemas: schemas} =
          validation
      )
      when is_map(value) do
    schema = %{schema | properties: schema.properties || %{}}

    {regular_properties, others} =
      value
      |> no_struct()
      |> Enum.split_with(fn {k, _v} -> is_binary(k) end)

    with {:ok, props} <- cast_properties(schema, regular_properties, schemas) do
      result = Map.new(others ++ props) |> make_struct(schema)
      {:ok, result}
    else
      {:error, v} -> {:error, %{validation | errors: v.errors}}
    end
  end

  def cast(%Validation{schema: ref = %Reference{}, schemas: schemas} = validation) do
    cast(%{validation | schema: Reference.resolve_schema(ref, schemas)})
  end

  def cast(%Validation{schema: _additionalProperties = false, value: value} = validation) do
    {:error, %{validation | errors: [Error.new(:unexpected_field, value)]}}
  end

  def cast(%Validation{value: value}), do: {:ok, value}

  defp make_struct(val = %_{}, _), do: val
  defp make_struct(val, %{"x-struct": nil}), do: val

  defp make_struct(val, %{"x-struct": mod}) do
    Enum.reduce(val, struct(mod), fn {k, v}, acc ->
      Map.put(acc, k, v)
    end)
  end

  defp no_struct(val), do: Map.delete(val, :__struct__)

  @spec cast_properties(Schema.t(), list, %{String.t() => Schema.t()}) ::
          {:ok, list} | {:error, Validation.t()}
  defp cast_properties(%Schema{}, [], _schemas), do: {:ok, []}

  defp cast_properties(object_schema = %Schema{}, [{key, value} | rest], schemas) do
    {name, schema} =
      Enum.find(
        object_schema.properties,
        {key, object_schema.additionalProperties},
        fn {name, _schema} -> to_string(name) == to_string(key) end
      )

    with {:ok, new_value} <- cast(%Validation{schema: schema, value: value, schemas: schemas}),
         {:ok, cast_tail} <- cast_properties(object_schema, rest, schemas) do
      {:ok, [{name, new_value} | cast_tail]}
    end
  end

  defp discriminate(%{value: value, schemas: schemas} = validator, discriminator) do
    case Discriminator.resolve(discriminator, value, schemas) do
      {:ok, derived_schema} -> {:ok, %{validator | schema: derived_schema}}
      {:error, error} -> {:error, %{validator | errors: [error]}}
    end
  end

  # Add an item to the path of each error
  defp add_to_error_paths(errors, item) do
    Enum.map(errors, fn error ->
      %{error | path: [item | error.path]}
    end)
  end
end
