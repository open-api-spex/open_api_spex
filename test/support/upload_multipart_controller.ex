defmodule OpenApiSpexTest.UploadMultipartController do
  @moduledoc tags: ["uploads"]

  use Phoenix.Controller
  use OpenApiSpex.Controller

  alias OpenApiSpexTest.Schemas

  plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true, replace_params: false

  @doc request_body: {"Files", "multipart/form-data", Schemas.UploadRequest},
       responses: [
         created: {"Files", "application/json", Schemas.UploadResponse}
       ]
  def create(conn, %{"files" => files}) do
    json(conn, %Schemas.UploadResponse{
      data: Enum.map(files, & &1.filename)
    })
  end
end
