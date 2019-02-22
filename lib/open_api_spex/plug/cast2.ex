defmodule OpenApiSpex.Plug.Cast2 do
  @behaviour Plug

  @impl Plug
  def init(opts) do
    IO.warn("OpenApiSpex.Plug.Cast2 is deprecated. Please use OpenApiSpex.Plug.CastAndValidate.")
    OpenApiSpex.Plug.CastAndValidate.init(opts)
  end

  @impl Plug
  def call(conn, opts) do
    IO.warn("OpenApiSpex.Plug.Cast2 is deprecated. Please use OpenApiSpex.Plug.CastAndValidate.")
    OpenApiSpex.Plug.CastAndValidate.call(conn, opts)
  end
end
