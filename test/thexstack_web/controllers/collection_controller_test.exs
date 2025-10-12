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

      # Create a collection for another user to ensure it's not returned
      other_user = user_fixture()
      _other_collection = collection_fixture(user: other_user)

      conn =
        conn
        |> auth_json_conn(user)
        |> get(~p"/api/collections")

      response = json_response(conn, 200)
      api_spec = PWeb.ApiSpec.spec()
      assert_schema(response, "CollectionListResponse", api_spec)

      assert length(response["data"]) == 1
      assert List.first(response["data"])["id"] == collection.id
      assert List.first(response["data"])["title"] == collection.title
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

      response = json_response(conn, 201)
      api_spec = PWeb.ApiSpec.spec()
      assert_schema(response, "CollectionShowResponse", api_spec)

      assert response["data"]["title"] == "My Vacation Photos"
      assert response["data"]["description"] == "Photos from our summer vacation"
      assert is_integer(response["data"]["id"])
    end

    test "creates a collection without description", %{conn: conn} do
      user = user_fixture()

      params = %{
        "title" => "My Collection"
      }

      conn =
        conn
        |> auth_json_conn(user)
        |> post(~p"/api/collections", params)

      response = json_response(conn, 201)
      assert response["data"]["title"] == "My Collection"
      assert response["data"]["description"] == nil
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

      response = json_response(conn, 422)
      assert response["errors"]["title"] == ["can't be blank"]
    end
  end

  describe "GET /api/collections/:id" do
    test "shows a collection owned by the user", %{conn: conn} do
      user = user_fixture()
      collection = collection_fixture(user: user)

      conn =
        conn
        |> auth_json_conn(user)
        |> get(~p"/api/collections/#{collection.id}")

      response = json_response(conn, 200)
      api_spec = PWeb.ApiSpec.spec()
      assert_schema(response, "CollectionShowResponse", api_spec)

      assert response["data"]["id"] == collection.id
      assert response["data"]["title"] == collection.title
      assert response["data"]["description"] == collection.description
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
        |> get(~p"/api/collections/99999")

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
end
