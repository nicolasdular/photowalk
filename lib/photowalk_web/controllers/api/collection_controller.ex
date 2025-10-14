defmodule PWeb.CollectionController do
  use PWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Schema
  alias P.Collections
  alias P.{Collection, Photo}
  alias PWeb.{CollectionJSON, PhotoJSON}
  alias PWeb.Schemas.EctoSchema

  action_fallback PWeb.FallbackController

  @photo_resource_schema EctoSchema.schema_from_fields(Photo,
                           description: "A processed photo with accessible variants",
                           fields: PhotoJSON.fields(),
                           required: PhotoJSON.required_fields(),
                           additional_properties: %{
                             thumbnail_url: %Schema{type: :string, format: :uri},
                             full_url: %Schema{type: :string, format: :uri},
                             allowed_to_delete: %Schema{type: :boolean}
                           }
                         )

  @collection_resource_schema EctoSchema.schema_from_fields(Collection,
                                description: "A collection of photos",
                                fields: CollectionJSON.fields(),
                                required: CollectionJSON.required_fields()
                              )

  @collection_list_response_schema %Schema{
    title: "CollectionListResponse",
    description: "List of collections for the current user",
    type: :object,
    properties: %{
      data: %Schema{
        type: :array,
        items: %Schema{
          allOf: [
            @collection_resource_schema,
            %Schema{
              type: :object,
              properties: %{
                thumbnails: %Schema{
                  type: :array,
                  items: @photo_resource_schema,
                  description: "Array of photo thumbnails for the collection"
                }
              }
            }
          ]
        }
      }
    },
    required: [:data]
  }

  @collection_show_response_schema %Schema{
    title: "CollectionShowResponse",
    description: "A single collection with its photos",
    type: :object,
    properties: %{
      data: %Schema{
        allOf: [
          @collection_resource_schema,
          %Schema{
            type: :object,
            properties: %{
              photos: %Schema{
                type: :array,
                items: %Schema{
                  allOf: [
                    @photo_resource_schema,
                    %Schema{
                      type: :object,
                      required: [:user],
                      properties: %{
                        user:
                          EctoSchema.schema_from_fields(P.User,
                            required: [:id, :email],
                            fields: PWeb.UserJSON.fields()
                          )
                      }
                    }
                  ]
                }
              }
            }
          }
        ]
      }
    },
    required: [:data]
  }

  @collection_create_request_schema %Schema{
    title: "CollectionCreateRequest",
    description: "Parameters for creating a collection",
    type: :object,
    properties: %{
      title: %Schema{type: :string, description: "Title of the collection"},
      description: %Schema{type: :string, description: "Description of the collection"}
    },
    required: [:title]
  }

  @collection_validation_error_schema %Schema{
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

  tags(["collections"])

  operation :index,
    summary: "List collections",
    responses: [
      ok: {"Collections", "application/json", @collection_list_response_schema}
    ]

  operation :create,
    summary: "Create a collection",
    request_body: {
      "CollectionCreateRequest",
      "application/json",
      @collection_create_request_schema,
      required: true
    },
    responses: [
      created: {
        "Created collection",
        "application/json",
        @collection_show_response_schema
      },
      unprocessable_entity: {
        "Validation errors",
        "application/json",
        @collection_validation_error_schema
      }
    ]

  operation :show,
    summary: "Show a collection",
    parameters: [
      id: [in: :path, description: "Collection ID", type: :string, required: true]
    ],
    responses: [
      ok: {"Collection", "application/json", @collection_show_response_schema},
      not_found: {"Collection not found", "application/json", %Schema{type: :object}}
    ]

  def index(conn, _params) do
    user = conn.assigns.current_user

    render(conn, :index,
      collections: Collections.list_collections_for_user(user),
      current_user: user
    )
  end

  def create(conn, params) do
    user = conn.assigns.current_user

    with {:ok, collection} <- Collections.create_collection(user, params) do
      conn
      |> put_status(:created)
      |> render(:show, collection: collection, current_user: user)
    end
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    with {:ok, collection} <-
           Collections.get_collection_for_user(id, user, %{
             preloads: [photos: :user]
           }) do
      render(conn, :show, collection: collection, current_user: user)
    end
  end
end
