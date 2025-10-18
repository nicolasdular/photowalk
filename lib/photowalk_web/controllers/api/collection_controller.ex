defmodule PWeb.CollectionController do
  use PWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Schema
  alias PWeb.Api.Docs.Response
  alias P.Collections
  alias PWeb.API.Resources.{CollectionDetail, CollectionSummary}
  alias PWeb.API.Resources.User, as: UserResource

  action_fallback PWeb.FallbackController

  tags(["collections"])

  operation :index,
    summary: "List collections",
    responses: [
      ok: Response.data_list(CollectionSummary.schema(), "CollectionListResponse")
    ]

  def index(conn, _params) do
    collections = Collections.list_collections(scope(conn))

    json(conn, %{data: present(conn, CollectionSummary, collections)})
  end

  operation :create,
    request_body: {
      "CollectionCreateRequest",
      "application/json",
      %Schema{
        title: "CollectionCreateRequest",
        description: "Parameters for creating a collection",
        type: :object,
        properties: %{
          title: %Schema{type: :string, description: "Title of the collection"},
          description: %Schema{type: :string, description: "Description of the collection"}
        },
        required: [:title]
      },
      required: true
    },
    responses: [
      created: Response.data(CollectionDetail.schema(), "CollectionCreateResponse"),
      unprocessable_entity: Response.validation_error()
    ]

  def create(conn, params) do
    with {:ok, collection} <- Collections.create_collection(scope(conn), params) do
      conn
      |> put_status(:created)
      |> json(%{
        data: present(conn, CollectionDetail, collection)
      })
    end
  end

  operation :update,
    summary: "Update a collection",
    parameters: [
      id: [in: :path, description: "Collection ID", type: :string, required: true]
    ],
    request_body: {
      "CollectionUpdateRequest",
      "application/json",
      %Schema{
        title: "CollectionUpdateRequest",
        description: "Parameters for updating a collection",
        type: :object,
        properties: %{
          title: %Schema{type: :string, description: "New title for the collection"},
          description: %Schema{type: :string, description: "New description for the collection"}
        }
      },
      required: true
    },
    responses: [
      ok: Response.data(CollectionDetail.schema(), "CollectionUpdateResponse"),
      not_found: Response.not_found(),
      unprocessable_entity: Response.validation_error()
    ]

  def update(conn, params) do
    with {:ok, collection} <- Collections.update_collection(scope(conn), params) do
      json(conn, %{
        data: present(conn, CollectionDetail, collection)
      })
    end
  end

  operation :show,
    parameters: [
      id: [in: :path, description: "Collection ID", schema: %Schema{type: :string, format: :uuid}, required: true]
    ],
    responses: [
      ok: Response.data(CollectionDetail.schema(), "CollectionShowResponse"),
      not_found: Response.not_found()
    ]

  def show(conn, %{"id" => id}) do
    with {:ok, collection} <- Collections.get_collection(scope(conn), id) do
      json(conn, %{data: present(conn, CollectionDetail, collection)})
    end
  end

  operation :add_user,
    summary: "Add a user to a collection",
    parameters: [
      collection_id: [
        in: :path,
        description: "Collection ID",
        type: :string,
        required: true
      ]
    ],
    request_body: {
      "AddUserToCollectionRequest",
      "application/json",
      %Schema{
        title: "AddUserToCollectionRequest",
        description: "Parameters for adding a user to a collection",
        type: :object,
        properties: %{
          email: %Schema{type: :string, format: :email, description: "Email of the user to add"}
        },
        required: [:email]
      },
      required: true
    },
    responses: [
      created: Response.data(UserResource.schema(), "AddUserToCollectionResponse"),
      not_found: Response.not_found(),
      unprocessable_entity: Response.validation_error()
    ]

  def add_user(conn, %{"collection_id" => collection_id, "email" => email}) do
    inviter_id = conn.assigns.current_user.id

    with {:ok, _member} <-
           Collections.add_user(scope(conn), %{
             collection_id: collection_id,
             email: email,
             inviter_id: inviter_id
           }),
         user when not is_nil(user) <- P.Accounts.get_user_by_email(scope(conn), email) do
      conn
      |> put_status(:created)
      |> json(%{data: present(conn, UserResource, user)})
    else
      nil -> {:error, :user_not_found}
      error -> error
    end
  end

  operation :list_users,
    summary: "List users in a collection",
    parameters: [
      collection_id: [
        in: :path,
        description: "Collection ID",
        type: :string,
        required: true
      ]
    ],
    responses: [
      ok: Response.data_list(UserResource.schema(), "CollectionUsersListResponse"),
      not_found: Response.not_found()
    ]

  def list_users(conn, %{"collection_id" => collection_id}) do
    scope = conn.assigns.current_scope

    with {:ok, collection} <- Collections.get_collection(scope, collection_id),
         users <- Collections.list_users(scope, collection) do
      json(conn, %{data: present(conn, UserResource, users)})
    end
  end
end
