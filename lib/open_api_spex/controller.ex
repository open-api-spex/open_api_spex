defmodule OpenApiSpex.Controller do
  @moduledoc ~S'''
  Generation of OpenAPI documentation via ExDoc documentation and tags.

  ## Supported OpenAPI fields

  Attribute `operationId` is automatically provided by the implementation
  and cannot be changed in any way. It is constructed as `Module.Name.function_name`
  in the same way as function references in backtraces.

  ### `description` and `summary`

  Description of endpoint will be filled with documentation string in the same
  manner as ExDocs, so first line will be used as a `summary` and whole
  documentation will be used as `description` field.

  ### `parameters`

  Parameters of the endpoint are defined by `:parameters` tag which should be
  map or keyword list that is formed as:

  ```
  [
    param_name: definition
  ]
  ```

  Where `definition` is `OpenApiSpex.Parameter.t()` structure or map or keyword
  list that accepts the same arguments.

  ### `responses`

  Responses are controlled by `:responses` tag. Responses must be defined as
  a map or keyword list in form of:

  ```
  %{
    200 => {"Response name", "application/json", schema},
    :not_found => {"Response name", "application/json", schema}
  }
  ```

  Where atoms are the same as `Plug.Conn.Status.code/1` values.

  ### `requestBody`

  Controlled by `:requestBody` parameter and is defined as a tuple in form
  `{description, mime, schema}` or `{description, mime, schema, opts} that
  match the arguments of `OpenApiSpex.Operation.request_body/3` or
  `OpenApiSpex.Operation.request_body/4`.

  ```
  @doc requestBody: {
    "CartUpdateRequest",
    "application/vnd.api+json",
    CartUpdateRequest,
    required: true
  }
  ```

  ### `tags`

  Tags are controlled by `:tags` attribute. In contrast to other attributes, this
  one will also inherit all tags defined as a module documentation attributes.

  ## Example

  ```
  defmodule FooController do
    use MyAppWeb, :controller
    use #{inspect(__MODULE__)}

    @moduledoc tags: ["Foos"]

    @doc """
    Endpoint summary

    Endpoint description...
    """
    @doc parameters: [
           id: [in: :path, type: :string, required: true]
         ],
         requestBody: {"Request body to update Foo", "application/json", FooUpdateBody, required: true},
         responses: [
           ok: {"Foo document", "application/json", FooSchema}
         ]
    def update(conn, %{id: id}) do
      foo_params = conn.body_params
      # …
    end
  end
  ```
  '''

  alias OpenApiSpex.Operation

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
    with {:ok, {mod_meta, summary, docs, meta}} <- get_docs(mod, name) do
      %Operation{
        description: docs,
        operationId: "#{inspect(mod)}.#{name}",
        parameters: build_parameters(meta),
        requestBody: build_request_body(meta),
        responses: build_responses(meta),
        summary: summary,
        tags: Map.get(mod_meta, :tags, []) ++ Map.get(meta, :tags, [])
      }
    else
      _ -> nil
    end
  end

  defp get_docs(module, name) do
    {:docs_v1, _anno, _lang, _format, _module_doc, mod_meta, mod_docs} = Code.fetch_docs(module)

    {_, _, _, docs, meta} =
      Enum.find(mod_docs, fn
        {{:function, ^name, _}, _, _, _, _} -> true
        _ -> false
      end)

    if docs == :none do
      :error
    else
      docs = Map.get(docs, "en", "")

      [summary | _] = String.split(docs, ~r/\n\s*\n/, parts: 2)

      {:ok, {mod_meta, summary, docs, meta}}
    end
  end

  defp build_parameters(%{parameters: params}) do
    for {name, options} <- params do
      {location, options} = Keyword.pop(options, :in, :query)
      {type, options} = Keyword.pop(options, :type, :string)
      {description, options} = Keyword.pop(options, :description, :string)

      Operation.parameter(name, location, type, description, options)
    end
  end

  defp build_parameters(_), do: []

  defp build_responses(%{responses: responses}) do
    for {status, {description, mime, schema}} <- responses, into: %{} do
      {Plug.Conn.Status.code(status), Operation.response(description, mime, schema)}
    end
  end

  defp build_responses(_), do: []

  defp build_request_body(%{body: {name, mime, schema}}) do
    IO.warn("Using :body key for requestBody is deprecated. Please use :requestBody instead.")
    Operation.request_body(name, mime, schema)
  end

  defp build_request_body(%{requestBody: {name, mime, schema}}) do
    Operation.request_body(name, mime, schema)
  end

  defp build_request_body(%{requestBody: {name, mime, schema, opts}}) do
    Operation.request_body(name, mime, schema, opts)
  end

  defp build_request_body(_), do: nil
end
