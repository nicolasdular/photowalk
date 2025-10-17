defmodule PWeb.PhotoController do
  use PWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Schema
  alias P.Photos
  alias PWeb.Api.Docs.Response
  alias PWeb.API.Resources.PhotoSummary

  action_fallback PWeb.FallbackController

  tags(["photos"])

  operation :index,
    summary: "List photos",
    responses: [
      ok: Response.data_list(PhotoSummary.schema(), "PhotoListResponse")
    ]

  def index(conn, _params) do
    user = conn.assigns.current_user

    photos =
      user
      |> Photos.list_photos_for_user()
      |> Enum.map(&PhotoSummary.build(&1, current_user: user))

    json(conn, %{data: photos})
  end

  operation :create,
    request_body: {
      "PhotoUploadRequest",
      "multipart/form-data",
      %Schema{
        title: "PhotoUploadRequest",
        type: :object,
        properties: %{
          photo: %Schema{
            type: :string,
            format: :binary,
            description: "Image file to process"
          },
          collection_id: %Schema{
            type: :string,
            format: :uuid,
            description: "Optional ID of the collection to add the photo to"
          }
        },
        required: [:photo]
      },
      required: true
    },
    responses: [
      created: Response.data(PhotoSummary.schema(), "PhotoCreateResponse"),
      unprocessable_entity: Response.validation_error()
    ]

  def create(conn, params) do
    scope = conn.assigns.current_scope
    user = scope.current_user

    with {:ok, photo} <- Photos.create_photo(scope, params["photo"], params) do
      conn
      |> put_status(:created)
      |> json(%{data: PhotoSummary.build(photo, current_user: user)})
    end
  end

  operation :delete,
    parameters: [
      id: [
        in: :path,
        required: true,
        schema: %Schema{type: :string, format: :uuid}
      ]
    ],
    responses: [
      no_content: {"Photo deleted", nil, nil},
      not_found: Response.not_found()
    ]

  def delete(conn, %{"id" => id}) do
    with {:ok, _photo} <- Photos.delete_photo(current_user(conn), id) do
      send_resp(conn, :no_content, "")
    end
  end
end
