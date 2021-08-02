defmodule OpenApiSpex.Plug.DefaultRenderError do
  @moduledoc false

  @deprecated "#{__MODULE__} is no longer the default error renderer"
  @behaviour Plug

  alias Plug.Conn

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, reason) do
    conn |> Conn.send_resp(422, "#{reason}")
  end
end
