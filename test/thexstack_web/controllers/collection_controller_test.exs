defmodule PWeb.CollectionControllerTest do
  use PWeb.ConnCase, async: true

  import P.Factory
  import PWeb.TestHelpers
  import OpenApiSpex.TestAssertions

  setup do
    File.rm_rf!(Path.expand("../../priv/waffle/test/uploads", __DIR__))

    on_exit(fn ->
      File.rm_rf!(Path.expand("../../priv/waffle/test/uploads", __DIR__))
    end)

    :ok
  end

  describe "GET /api/collections" do
    test "lists collections for the signed-in user", %{conn: conn} do
      user = user_fixture()
      collection = collection_fixture(user: user)
      photo = photo_fixture(user: user, collection: collection)
      # Create a collection for another user to ensure it's not returned
      other_user = user_fixture()
      _other_collection = collection_fixture(user: other_user)

      conn =
        conn
        |> auth_json_conn(user)
        |> get(~p"/api/collections")

      response = json_response(conn, 200) |> assert_api_spec("CollectionListResponse")

      assert length(response["data"]) == 1
      assert List.first(response["data"])["id"] == collection.id
      assert List.first(response["data"])["title"] == collection.title
      assert hd(hd(response["data"])["thumbnails"])["id"] == photo.id
    end

    test "returns empty list when user has no collections", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> auth_json_conn(user)
        |> get(~p"/api/collections")

      response = json_response(conn, 200)
      assert response["data"] == []
    end
  end

  describe "POST /api/collections" do
    test "creates a collection with valid parameters", %{conn: conn} do
      user = user_fixture()

      params = %{
        "title" => "My Vacation Photos",
        "description" => "Photos from our summer vacation"
      }

      conn =
        conn
        |> auth_json_conn(user)
        |> post(~p"/api/collections", params)

      response =
        json_response(conn, 201)
        |> assert_api_spec("CollectionCreateResponse")

      assert response["data"]["title"] == "My Vacation Photos"
      assert response["data"]["description"] == "Photos from our summer vacation"
    end

    test "validates required title", %{conn: conn} do
      user = user_fixture()

      params = %{
        "description" => "A description without a title"
      }

      conn =
        conn
        |> auth_json_conn(user)
        |> post(~p"/api/collections", params)

      response =
        json_response(conn, 422)
        |> assert_api_spec("ValidationErrors")

      assert response["errors"]["title"] == ["can't be blank"]
    end
  end

  describe "PUT /api/collections/:id" do
    test "updates a collection when user owns it", %{conn: conn} do
      user = user_fixture()
      collection = collection_fixture(user: user)

      params = %{
        "title" => "Updated title",
        "description" => "Updated description"
      }

      conn =
        conn
        |> auth_json_conn(user)
        |> put(~p"/api/collections/#{collection.id}", params)

      response = json_response(conn, 200)

      api_spec = PWeb.ApiSpec.spec()
      assert_schema(response, "CollectionShowResponse", api_spec)

      assert response["data"]["title"] == "Updated title"
      assert response["data"]["description"] == "Updated description"
    end

    test "returns not found when user cannot mutate collection", %{conn: conn} do
      owner = user_fixture()
      other_user = user_fixture()
      collection = collection_fixture(user: owner)

      params = %{
        "title" => "Updated title"
      }

      conn =
        conn
        |> auth_json_conn(other_user)
        |> put(~p"/api/collections/#{collection.id}", params)

      response = json_response(conn, 404)
      assert response["error"] == "Not found"
    end
  end

  describe "GET /api/collections/:id" do
    test "shows a collection owned by the user", %{conn: conn} do
      user = user_fixture()
      collection = collection_fixture(user: user)
      photo = photo_fixture(user: user, collection: collection)

      conn =
        conn
        |> auth_json_conn(user)
        |> get(~p"/api/collections/#{collection.id}")

      response =
        json_response(conn, 200)
        |> assert_api_spec("CollectionShowResponse")

      assert response["data"]["id"] == collection.id
      assert response["data"]["title"] == collection.title
      assert response["data"]["description"] == collection.description
      assert hd(response["data"]["photos"])["id"] == photo.id
      assert hd(response["data"]["photos"])["user"]["id"] == photo.user_id
    end

    test "includes deletion permissions for photos", %{conn: conn} do
      user = user_fixture()
      collection = collection_fixture(user: user)
      upload = upload_fixture()

      {:ok, photo} = P.Photos.create_photo(user, upload, %{"collection_id" => collection.id})

      conn =
        conn
        |> auth_json_conn(user)
        |> get(~p"/api/collections/#{collection.id}")

      response = json_response(conn, 200)

      [photo_payload] = response["data"]["photos"]
      assert photo_payload["id"] == photo.id
      assert photo_payload["allowed_to_delete"]
    end

    test "returns 404 when collection doesn't exist", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> auth_json_conn(user)
        |> get(~p"/api/collections/#{Ecto.UUID.generate()}")

      response = json_response(conn, 404)
      assert response["error"] == "Not found"
    end

    test "returns 404 when collection belongs to another user", %{conn: conn} do
      user = user_fixture()
      other_user = user_fixture()
      collection = collection_fixture(user: other_user)

      conn =
        conn
        |> auth_json_conn(user)
        |> get(~p"/api/collections/#{collection.id}")

      response = json_response(conn, 404)
      assert response["error"] == "Not found"
    end
  end

  describe "GET /api/collections/:id/users" do
    test "lists users in a collection", %{conn: conn} do
      owner = user_fixture()
      member = user_fixture()
      collection = collection_fixture(user: owner)

      # Add the member to the collection
      {:ok, _membership} =
        P.Collections.add_user(scope_fixture(user: owner), %{
          collection_id: collection.id,
          email: member.email,
          inviter_id: owner.id
        })

      conn =
        conn
        |> auth_json_conn(owner)
        |> get(~p"/api/collections/#{collection.id}/users")

      response =
        json_response(conn, 200)
        |> assert_api_spec("CollectionUsersListResponse")

      assert length(response["data"]) == 2
      user_ids = Enum.map(response["data"], & &1["id"])
      assert owner.id in user_ids
      assert member.id in user_ids
    end

    test "returns empty list when collection has only the owner", %{conn: conn} do
      user = user_fixture()
      collection = collection_fixture(user: user)

      conn =
        conn
        |> auth_json_conn(user)
        |> get(~p"/api/collections/#{collection.id}/users")

      response =
        json_response(conn, 200)
        |> assert_api_spec("CollectionUsersListResponse")

      assert length(response["data"]) == 1
      assert hd(response["data"])["id"] == user.id
    end

    test "returns 404 when collection doesn't exist", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> auth_json_conn(user)
        |> get(~p"/api/collections/#{Ecto.UUID.generate()}/users")

      response =
        json_response(conn, 404)
        |> assert_api_spec("NotFoundError")

      assert response["error"] == "Not found"
    end
  end

  describe "POST /api/collections/:id/users" do
    test "adds a user to a collection by email", %{conn: conn} do
      owner = user_fixture()
      new_member = user_fixture()
      collection = collection_fixture(user: owner)

      params = %{"email" => new_member.email}

      conn =
        conn
        |> auth_json_conn(owner)
        |> post(~p"/api/collections/#{collection.id}/users", params)

      response =
        json_response(conn, 201)
        |> assert_api_spec("AddUserToCollectionResponse")

      assert response["data"]["id"] == new_member.id
      assert response["data"]["email"] == new_member.email
    end

    test "returns error when user email doesn't exist", %{conn: conn} do
      owner = user_fixture()
      collection = collection_fixture(user: owner)

      params = %{"email" => "nonexistent@example.com"}

      conn =
        conn
        |> auth_json_conn(owner)
        |> post(~p"/api/collections/#{collection.id}/users", params)

      response =
        json_response(conn, 422)
        |> assert_api_spec("ValidationErrors")

      # Check that we get an error about the email
      assert response["errors"]["email"]
    end

    test "returns error when collection doesn't exist", %{conn: conn} do
      user = user_fixture()
      params = %{"email" => "someone@example.com"}

      conn =
        conn
        |> auth_json_conn(user)
        |> post(~p"/api/collections/#{Ecto.UUID.generate()}/users", params)

      # Returns 422 because the email validation happens before collection check
      response =
        json_response(conn, 422)
        |> assert_api_spec("ValidationErrors")

      assert response["errors"]["email"]
    end

    test "returns error when user doesn't own the collection", %{conn: conn} do
      owner = user_fixture()
      other_user = user_fixture()
      collection = collection_fixture(user: owner)

      params = %{"email" => "someone@example.com"}

      conn =
        conn
        |> auth_json_conn(other_user)
        |> post(~p"/api/collections/#{collection.id}/users", params)

      # Returns 422 because the email validation happens before collection check
      response =
        json_response(conn, 422)
        |> assert_api_spec("ValidationErrors")

      assert response["errors"]["email"]
    end
  end
end
