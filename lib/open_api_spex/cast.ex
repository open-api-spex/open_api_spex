defmodule OpenApiSpex.Cast do
  @moduledoc false
  alias OpenApiSpex.{Error, Discriminator, Reference, Schema, Validation}
  alias OpenApiSpex.Cast.Primitives

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

  ## nullable: true, given nil

  def cast(%Validation{schema: %{nullable: true}, value: nil}) do
    {:ok, nil}
  end

  ## Primitive types

  def cast(%Validation{schema: %{type: type}} = validation) when type in [:boolean, :integer, :number, :string] do
    Primitives.cast(validation)
  end

  ## type: :array

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

  ## type: :object

  # Unexpected type instead of map
  def cast(%Validation{schema: %{type: :object}, value: value} = validation)
      when not is_map(value) do
    {:error, %{validation | errors: [Error.new(:invalid_type, :object, value)]}}
  end

  # With discriminator
  # A discriminator enables inheritance
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
          cast_partial_object(%{
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

  ## With oneOf defined

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

  ## With anyOf defined

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

  ## Fallback type: object

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

  ## schema: %Reference{}

  def cast(%Validation{schema: ref = %Reference{}, schemas: schemas} = validation) do
    cast(%{validation | schema: Reference.resolve_schema(ref, schemas)})
  end

  ## No schema

  def cast(%Validation{schema: _additionalProperties = false, value: value} = validation) do
    {:error, %{validation | errors: [Error.new(:unexpected_field, value)]}}
  end

  ## Default

  def cast(%Validation{value: value}) do
    {:ok, value}
  end

  ## Private functions

  # Like cast/1, but pass through unrecognized properties without rejecting them
  defp cast_partial_object(
    %Validation{schema: schema = %Schema{type: :object}, value: value, schemas: schemas} =
      validation
  )
  when is_map(value) do
    schema = %{schema | properties: schema.properties || %{}}

    {regular_properties, others} =
      value
      |> no_struct()
      |> Enum.split_with(fn {k, _v} -> is_binary(k) end)

    with {:ok, props} <- cast_partial_properties(schema, regular_properties, schemas) do
      result = Map.new(others ++ props) |> make_struct(schema)
      {:ok, result}
    else
      {:error, v} -> {:error, %{validation | errors: v.errors}}
    end
  end

  defp make_struct(val = %_{}, _), do: val
  defp make_struct(val, %{"x-struct": nil}), do: val

  defp make_struct(val, %{"x-struct": mod}) do
    Enum.reduce(val, struct(mod), fn {k, v}, acc ->
      Map.put(acc, k, v)
    end)
  end

  defp no_struct(val), do: Map.delete(val, :__struct__)

  # Cast properties, allowing only recognized ones
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

    if schema do
      with {:ok, new_value} <- cast(%Validation{schema: schema, value: value, schemas: schemas}),
            {:ok, cast_tail} <- cast_properties(object_schema, rest, schemas) do
        {:ok, [{name, new_value} | cast_tail]}
      end
    else
      error = %Validation{
        schema: object_schema,
        schemas: schemas,
        value: value,
        errors: [Error.new(:unexpected_field, key)]
      }

      {:error, error}
    end
  end

  # Cast properties and allow unrecognized ones to pass through
  defp cast_partial_properties(%Schema{}, [], _schemas), do: {:ok, []}

  defp cast_partial_properties(object_schema = %Schema{}, [{key, value} | rest], schemas) do
    {name, schema} =
      Enum.find(
        object_schema.properties,
        {key, object_schema.additionalProperties},
        fn {name, _schema} -> to_string(name) == to_string(key) end
      )

    with {:ok, new_value} <- cast(%Validation{schema: schema, value: value, schemas: schemas}),
         {:ok, cast_tail} <- cast_partial_properties(object_schema, rest, schemas) do
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
