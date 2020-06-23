defmodule OpenApiSpex.Plug.JsonRenderError do
  @doc """
  Renders errors using a json:api-compliant data shape.
  """
  @behaviour Plug

  alias Plug.Conn
  alias OpenApiSpex.OpenApi

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, errors) when is_list(errors) do
    response = %{
      errors: Enum.map(errors, &render_error/1)
    }

    json = OpenApi.json_encoder().encode!(response)

    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(422, json)
  end

  def call(conn, reason) do
    call(conn, [reason])
  end

  defp render_error(error) do
    pointer = OpenApiSpex.path_to_string(error)

    %{
      title: "Invalid value",
      source: %{
        pointer: pointer
      },
      detail: to_string(error),
      # message is deprecated because it isn't part of the json:api spec.
      message: to_string(error)
    }
  end
end
