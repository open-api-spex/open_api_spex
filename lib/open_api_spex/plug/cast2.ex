defmodule OpenApiSpex.Plug.Cast2 do
  @moduledoc false

  @behaviour Plug

  @impl Plug
  @deprecated "Use OpenApiSpex.Plug.CastAndValidate.init/1 instead"
  defdelegate init(opts), to: OpenApiSpex.Plug.CastAndValidate

  @impl Plug
  @deprecated "Use OpenApiSpex.Plug.CastAndValidate.call/2 instead"
  defdelegate call(conn, opts), to: OpenApiSpex.Plug.CastAndValidate
end
