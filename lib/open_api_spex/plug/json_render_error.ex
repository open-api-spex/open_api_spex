defmodule OpenApiSpex.Plug.JsonRenderError do
  @moduledoc false

  # Renders errors using a quasi-json:api-compliant data shape.
  # This module will change in a backwards-incompatible way in version 4.0.

  @behaviour Plug

  alias OpenApiSpex.OpenApi
  alias Plug.Conn

  @impl Plug
  def init(errors), do: errors

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
      message: to_string(error)
    }
  end
end
