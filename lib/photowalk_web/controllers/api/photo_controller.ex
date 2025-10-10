defmodule PWeb.PhotoController do
  use PWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Schema
  alias P.Photos
  alias P.Photo
  alias PWeb.PhotoJSON
  alias PWeb.Schemas.EctoSchema

  action_fallback PWeb.FallbackController

  @photo_resource_schema EctoSchema.schema_from_fields(Photo,
                           description: "A processed photo with accessible variants",
                           fields: PhotoJSON.fields(),
                           required: PhotoJSON.required_fields(),
                           additional_properties: %{
                             thumbnail_url: %Schema{type: :string, format: :uri},
                             full_url: %Schema{type: :string, format: :uri}
                           }
                         )

  @photo_list_response_schema %Schema{
    title: "PhotoListResponse",
    description: "List of photos for the current user",
    type: :object,
    properties: %{
      data: %Schema{type: :array, items: @photo_resource_schema}
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
        type: :integer,
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

  tags(["photos"])

  operation :index,
    summary: "List photos",
    responses: [
      ok: {"Photos", "application/json", @photo_list_response_schema}
    ]

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

  def index(conn, _params) do
    user = conn.assigns.current_user

    render(conn, :index, photos: Photos.list_photos_for_user(user))
  end

  def create(conn, params) do
    user = conn.assigns.current_user

    with {:ok, photo} <- Photos.create_photo(user, params["photo"], params) do
      conn
      |> put_status(:created)
      |> render(:index, photos: [photo])
    end
  end
end
