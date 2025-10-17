defmodule PWeb.CollectionController do
  use PWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Schema
  alias P.Collections
  alias PWeb.API.Resources.{CollectionDetail, CollectionSummary}
  alias PWeb.API.Resources.User, as: UserResource

  action_fallback PWeb.FallbackController

  @collection_list_response_schema %Schema{
    title: "CollectionListResponse",
    description: "List of collections for the current user",
    type: :object,
    properties: %{
      data: %Schema{
        type: :array,
        items: CollectionSummary.schema()
      }
    },
    required: [:data]
  }

  @collection_show_response_schema %Schema{
    title: "CollectionShowResponse",
    description: "A single collection with its photos",
    type: :object,
    properties: %{
      data: CollectionDetail.schema()
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

  @collection_update_request_schema %Schema{
    title: "CollectionUpdateRequest",
    description: "Parameters for updating a collection",
    type: :object,
    properties: %{
      title: %Schema{type: :string, description: "New title for the collection"},
      description: %Schema{type: :string, description: "New description for the collection"}
    }
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

  @add_user_request_schema %Schema{
    title: "AddUserToCollectionRequest",
    description: "Parameters for adding a user to a collection",
    type: :object,
    properties: %{
      email: %Schema{type: :string, format: :email, description: "Email of the user to add"}
    },
    required: [:email]
  }

  @user_response_schema %Schema{
    title: "UserResponse",
    description: "Response containing user data",
    type: :object,
    properties: %{
      data: UserResource.schema()
    },
    required: [:data]
  }

  @users_list_response_schema %Schema{
    title: "UsersListResponse",
    description: "List of users in a collection",
    type: :object,
    properties: %{
      data: %Schema{
        type: :array,
        items: UserResource.schema()
      }
    },
    required: [:data]
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

  operation :update,
    summary: "Update a collection",
    parameters: [
      id: [in: :path, description: "Collection ID", type: :string, required: true]
    ],
    request_body: {
      "CollectionUpdateRequest",
      "application/json",
      @collection_update_request_schema,
      required: true
    },
    responses: [
      ok: {
        "Updated collection",
        "application/json",
        @collection_show_response_schema
      },
      not_found: {"Collection not found", "application/json", %Schema{type: :object}},
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

  operation :add_user,
    summary: "Add a user to a collection",
    parameters: [
      id: [in: :path, description: "Collection ID", type: :string, required: true]
    ],
    request_body: {
      "AddUserToCollectionRequest",
      "application/json",
      @add_user_request_schema,
      required: true
    },
    responses: [
      created: {
        "User added to collection",
        "application/json",
        @user_response_schema
      },
      not_found: {"Collection not found", "application/json", %Schema{type: :object}},
      unprocessable_entity: {
        "Validation errors",
        "application/json",
        @collection_validation_error_schema
      }
    ]

  operation :list_users,
    summary: "List users in a collection",
    parameters: [
      id: [in: :path, description: "Collection ID", type: :string, required: true]
    ],
    responses: [
      ok: {"Users in collection", "application/json", @users_list_response_schema},
      not_found: {"Collection not found", "application/json", %Schema{type: :object}}
    ]

  def index(conn, _params) do
    scope = conn.assigns.current_scope
    current_user = conn.assigns.current_user

    collections =
      scope
      |> Collections.list_collections()
      |> Enum.map(&CollectionSummary.from_collection(&1, current_user: current_user))

    json(conn, %{data: collections})
  end

  def create(conn, params) do
    scope = conn.assigns.current_scope
    current_user = conn.assigns.current_user

    with {:ok, collection} <- Collections.create_collection(scope, params),
         {:ok, detailed_collection} <-
           Collections.get_collection(scope, collection.id, %{preloads: [photos: :user]}) do
      conn
      |> put_status(:created)
      |> json(%{
        data: CollectionDetail.from_collection(detailed_collection, current_user: current_user)
      })
    end
  end

  def update(conn, params) do
    scope = scope(conn)
    current_user = current_user(conn)

    with {:ok, collection} <- Collections.update_collection(scope, params),
         {:ok, detailed_collection} <-
           Collections.get_collection(scope, collection.id, %{preloads: [photos: :user]}) do
      json(conn, %{
        data: CollectionDetail.from_collection(detailed_collection, current_user: current_user)
      })
    end
  end

  def show(conn, %{"id" => id}) do
    current_user = current_user(conn)

    with {:ok, collection} <-
           Collections.get_collection(scope(conn), id, %{
             preloads: [photos: :user]
           }) do
      json(conn, %{data: CollectionDetail.from_collection(collection, current_user: current_user)})
    end
  end

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
      |> json(%{data: UserResource.serialize(user)})
    else
      nil -> {:error, :user_not_found}
      error -> error
    end
  end

  def list_users(conn, %{"collection_id" => collection_id}) do
    scope = conn.assigns.current_scope

    with {:ok, collection} <- Collections.get_collection(scope, collection_id),
         users <- Collections.list_users(scope, collection) do
      json(conn, %{data: Enum.map(users, &UserResource.serialize/1)})
    end
  end
end
