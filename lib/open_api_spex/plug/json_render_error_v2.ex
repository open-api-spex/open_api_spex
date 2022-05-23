defmodule OpenApiSpex.Plug.JsonRenderErrorV2 do
  @moduledoc """
  Renders errors using a quasi-json:api-compliant data shape.

  WARNING: Do not use this module directly. It will be renamed in version 4.0
  To use this module in a backwards-compatible way, call CastAndValidate like this:

      plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true
  """
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
      detail: to_string(error)
    }
  end
end
