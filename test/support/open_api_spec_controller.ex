defmodule OpenApiSpexTest.OpenApiSpecController do
  alias OpenApiSpexTest.ApiSpec

  def init(:show), do: :show
  def call(conn, :show) do
    Phoenix.Controller.json(conn, ApiSpec.spec())
  end
end