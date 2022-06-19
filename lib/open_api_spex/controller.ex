defmodule OpenApiSpex.Controller do
  @moduledoc ~S'''
  Generation of OpenAPI documentation via ExDoc documentation and tags.

  Note: For projects using Elixir releases, [there is an issue](https://github.com/open-api-spex/open_api_spex/issues/242) that
  potentially breaks OpenApiSpex's integration with your application. Please use `OpenApiSpex.ControllerSpecs` instead.

  ## Supported OpenAPI fields

  ### `description` and `summary`

  Description of endpoint will be filled with documentation string in the same
  manner as ExDocs, so first line will be used as a `summary` and the rest of it
  will be used as `description` field.

  ### `operation_id`

  The action's `operation_id` can be set explicitly using a `@doc` tag.
  If no `operation_id` is specified, it will default to the action's module path: `Module.Name.function_name`

  ### `parameters`

  Parameters of the endpoint are defined by `:parameters` tag which should be
  map or list that is formed as:

  ```elixir
  [
    param_name: definition
  ]

  # or

  [
    structure_definition
  ]
  ```

  Where `definition` is map or keyword list that accepts the same arguments.
  Where `structure_definition` is `OpenApiSpex.Parameter.t()` or `OpenApiSpex.Reference.t()` structure
  that accepts the same arguments.

  Example:

  ```elixir
  @doc parameters: [
    group_id: [in: :path, type: :integer, description: "Group ID", example: 1]
  ]
  ```

  or

  ```elixir
  @doc parameters: [
    %OpenApiSpex.Parameter{
      in: :path,
      name: :group_id,
      description: "Group ID",
      schema: %Schema{type: :integer},
      required: true,
      example: 1
    }
  ]
  ```

  or

  ```elixir
  @doc parameters: [
    "$ref": "#/components/parameters/group_id"
    # or
    %OpenApiSpex.Reference{"$ref": "#/components/parameters/group_id"}
  ]
  ```

  ### `responses`

  Responses are controlled by `:responses` tag. Responses must be defined as
  a map or keyword list in form of:

  ```
  %{
    200 => {"Response name", "application/json", schema},
    :not_found => {"Response name", "application/json", schema}
  }
  ```

  Or:
  ```
  [
    ok: {"Response name", "application/json", schema},
    not_found: {"Response name", "application/json", schema}
  ]
  ```

  If a response has no body, the definition may be simplified further:

  ```
  [
    no_content: "Empty response"
  ]
  ```

  For each key in the key-value list of map, either an HTTP status code can be used or its atom equivalent.

  The full set of atom keys are defined in `Plug.Conn.Status.code/1`.

  ### `requestBody`

  Controlled by `:request_body` parameter and is defined as a tuple in form
  `{description, mime, schema}` or `{description, mime, schema, opts}` that
  matches the arguments of `OpenApiSpex.Operation.request_body/3` or
  `OpenApiSpex.Operation.request_body/4`, respectively.

  ```
  @doc request_body: {
    "CartUpdateRequest",
    "application/vnd.api+json",
    CartUpdateRequest,
    required: true
  }
  ```

  ### `security`

  Allows specifying the security scheme(s) required for this operation.  See
  `OpenApiSpex.Operation` and `OpenApiSpex.SecurityRequirement`.

  ### `tags`

  Tags are controlled by `:tags` attribute. In contrast to other attributes, this
  one will also inherit all tags defined as a module documentation attributes.

  ## Example

  ```
  defmodule UserController do
    @moduledoc tags: ["Users"]

    use MyAppWeb, :controller
    use OpenApiSpex.Controller

    @doc """
    Endpoint summary

    Endpoint description...
    """
    @doc parameters: [
           id: [in: :path, type: :string, required: true]
         ],
         request_body: {"Request body to update User", "application/json", UserUpdateBody, required: true},
         responses: [
           ok: {"User document", "application/json", UserSchema},
           {302, "Redirect", "text/html", EmptyResponse, headers: %{"Location" => %Header{description: "Redirect Location"}}}
         ]
    def update(conn, %{id: id}) do
      user_params = conn.body_params
      # …
    end
  end
  ```
  '''

  alias OpenApiSpex.{Operation, OperationBuilder}

  defmacro __using__(_opts) do
    quote do
      @doc false
      @spec open_api_operation(atom()) :: OpenApiSpex.Operation.t()
      def open_api_operation(name),
        do: unquote(__MODULE__).__api_operation__(__MODULE__, name)

      defoverridable open_api_operation: 1
    end
  end

  @doc false
  @spec __api_operation__(module(), atom()) :: Operation.t() | nil
  def __api_operation__(mod, name) do
    case get_docs(mod, name) do
      {:ok, {mod_meta, summary, description, meta}} ->
        %Operation{
          summary: summary,
          externalDocs: OperationBuilder.build_external_docs(meta, mod_meta),
          description: description || "",
          operationId: OperationBuilder.build_operation_id(meta, mod, name),
          parameters: OperationBuilder.build_parameters(meta),
          requestBody: OperationBuilder.build_request_body(meta),
          responses: OperationBuilder.build_responses(meta),
          security: OperationBuilder.build_security(meta, mod_meta),
          tags: OperationBuilder.build_tags(meta, mod_meta)
        }

      _ ->
        nil
    end
  end

  defp get_docs(module, name) do
    {:docs_v1, _anno, _lang, _format, _module_doc, mod_meta, mod_docs} = Code.fetch_docs(module)

    mod_docs
    |> Enum.find(mod_docs, fn
      {{:function, ^name, _}, _, _, _, _} -> true
      _ -> false
    end)
    |> doc_for_function(module, name, mod_meta)
  end

  defp doc_for_function({_, _, _, :hidden, _}, _module, _name, _mod_meta), do: nil

  defp doc_for_function({_, _, _, docs, meta}, module, name, mod_meta) when is_map(meta) do
    cond do
      Enum.empty?(meta) ->
        IO.warn("No docs found for function #{module}.#{name}/2")
        nil

      not Map.has_key?(meta, :responses) ->
        IO.warn("No responses declaration found for function #{module}.#{name}/2")
        nil

      true ->
        {summary, description} =
          case docs do
            %{"en" => contents} ->
              [summary | maybe_description] = String.split(contents, ~r/\n\s*\n/, parts: 2)
              {summary, List.first(maybe_description) || ""}

            _ ->
              {"", ""}
          end

        {:ok, {mod_meta, summary, description, meta}}
    end
  end

  defp doc_for_function(_doc_for_function, module, name, _mod_meta) do
    IO.warn("Invalid docs declaration found for function #{module}.#{name}/2")
    nil
  end
end
