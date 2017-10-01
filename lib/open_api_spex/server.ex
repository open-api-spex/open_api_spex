defmodule OpenApiSpex.Server do
  alias OpenApiSpex.{Server, ServerVariable}
  defstruct [
    :url,
    :description,
    variables: %{}
  ]
  @type t :: %Server{
    url: String.t,
    description: String.t | nil,
    variables: %{String.t => ServerVariable.t}
  }

  @doc """
  Builds a Server from a phoenix Endpoint module
  """
  @spec from_endpoint(module, [otp_app: atom]) :: t
  def from_endpoint(endpoint, opts) do
    app = opts[:otp_app]
    url_config = Application.get_env(app, endpoint, []) |> Keyword.get(:url, [])
    scheme = Keyword.get(url_config, :scheme, "http")
    host = Keyword.get(url_config, :host, "localhost")
    port = Keyword.get(url_config, :port, "80")
    path = Keyword.get(url_config, :path, "/")
    %Server{
      url: "#{scheme}://#{host}:#{port}#{path}"
    }
  end
end