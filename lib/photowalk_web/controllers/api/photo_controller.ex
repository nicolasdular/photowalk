defmodule PWeb.PhotoController do
  use PWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Schema
  alias P.Photos
  alias PWeb.API.Resources.PhotoSummary

  action_fallback PWeb.FallbackController

  @photo_list_response_schema %Schema{
    title: "PhotoListResponse",
    description: "List of photos for the current user",
    type: :object,
    properties: %{
      data: %Schema{type: :array, items: PhotoSummary.schema()}
    },
    required: [:data]
  }

  @photo_upload_request_schema %Schema{
    title: "PhotoUploadRequest",
    description: "Multipart payload accepting a single photo",
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
  }

  @photo_validation_error_schema %Schema{
    title: "ValidationErrors",
    type: :object,
    properties: %{
      errors: %Schema{
        type: :object,
        additionalProperties: %Schema{type: :array, items: %Schema{type: :string}}
      }
    },
    required: [:errors]
  }

  @not_found_schema %Schema{
    title: "NotFoundError",
    type: :object,
    properties: %{
      error: %Schema{type: :string, description: "Error message"}
    },
    required: [:error]
  }

  tags(["photos"])

  operation :index,
    summary: "List photos",
    responses: [
      ok: {"Photos", "application/json", @photo_list_response_schema}
    ]

  operation :delete,
    summary: "Delete photo",
    parameters: [
      id: [
        in: :path,
        description: "Photo ID",
        required: true,
        schema: %Schema{type: :string, format: :uuid}
      ]
    ],
    responses: [
      no_content: {"Photo deleted", nil, nil},
      not_found: {"Not found", "application/json", @not_found_schema}
    ]

  def index(conn, _params) do
    user = conn.assigns.current_user

    photos =
      user
      |> Photos.list_photos_for_user()
      |> Enum.map(&PhotoSummary.from_photo(&1, current_user: user))

    json(conn, %{data: photos})
  end

  operation :create,
    summary: "Upload a photo",
    request_body: {
      "PhotoUploadRequest",
      "multipart/form-data",
      @photo_upload_request_schema,
      required: true
    },
    responses: [
      created: {
        "Uploaded photos",
        "application/json",
        @photo_list_response_schema
      },
      unprocessable_entity: {
        "Validation errors",
        "application/json",
        @photo_validation_error_schema
      }
    ]

  def create(conn, params) do
    user = conn.assigns.current_user

    with {:ok, photo} <- Photos.create_photo(user, params["photo"], params) do
      conn
      |> put_status(:created)
      |> json(%{data: [PhotoSummary.from_photo(photo, current_user: user)]})
    end
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    with {:ok, _photo} <- Photos.delete_photo(user, id) do
      send_resp(conn, :no_content, "")
    end
  end
end
