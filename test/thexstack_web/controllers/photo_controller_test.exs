defmodule PWeb.PhotoControllerTest do
  use PWeb.ConnCase, async: false

  import P.Factory
  import PWeb.TestHelpers
  import OpenApiSpex.TestAssertions
  alias PWeb.API.Resources.PhotoSummary

  setup do
    File.rm_rf!(Path.expand("../../priv/waffle/test/uploads", __DIR__))

    on_exit(fn ->
      File.rm_rf!(Path.expand("../../priv/waffle/test/uploads", __DIR__))
    end)

    :ok
  end

  describe "POST /api/photos" do
    test "uploads and processes a photo", %{conn: conn} do
      user = user_fixture()
      upload = upload_fixture()

      conn =
        conn
        |> auth_json_conn(user)
        |> post(~p"/api/photos", %{"photo" => upload})

      response = json_response(conn, 201)
      api_spec = PWeb.ApiSpec.spec()

      assert_schema(response, "PhotoCreateResponse", api_spec)

      %{"thumbnail_url" => thumb_url, "full_url" => full_url, "allowed_to_delete" => allowed?} = response["data"]

      assert thumb_url =~ "/uploads/"
      assert full_url =~ "/uploads/"
      assert allowed?

      assert File.exists?(local_path(thumb_url))
      assert File.exists?(local_path(full_url))

      dir = thumb_url |> local_path() |> Path.dirname()

      assert Enum.sort(Path.wildcard(Path.join(dir, "*.jpg"))) ==
               Enum.sort([
                 Path.join(dir, "full.jpg"),
                 Path.join(dir, "thumb.jpg")
               ])
    end

    test "validates missing files", %{conn: conn} do
      user = user_fixture()

      conn
      |> auth_json_conn(user)
      |> post(~p"/api/photos", %{})
      |> json_response(422)
    end

    test "uploads a photo to a collection", %{conn: conn} do
      user = user_fixture()
      collection = collection_fixture(user: user)
      upload = upload_fixture()

      conn =
        conn
        |> auth_json_conn(user)
        |> post(~p"/api/photos", %{"photo" => upload, "collection_id" => collection.id})

      response = json_response(conn, 201) |> assert_api_spec("PhotoCreateResponse")

      photo = P.Repo.get(P.Photo, response["data"]["id"])
      assert photo.collection_id == collection.id
    end

    test "validates collection belongs to user", %{conn: conn} do
      user = user_fixture()
      other_user = user_fixture()
      other_collection = collection_fixture(user: other_user)
      upload = upload_fixture()

      conn =
        conn
        |> auth_json_conn(user)
        |> post(~p"/api/photos", %{"photo" => upload, "collection_id" => other_collection.id})

      response =
        json_response(conn, 422)
        |> assert_api_spec("ValidationErrors")

      assert response["errors"]["collection_id"] == ["does not belong to you"]
    end

    test "validates collection exists", %{conn: conn} do
      user = user_fixture()
      upload = upload_fixture()

      conn =
        conn
        |> auth_json_conn(user)
        |> post(~p"/api/photos", %{"photo" => upload, "collection_id" => Ecto.UUID.generate()})

      response = json_response(conn, 422)
      assert response["errors"]["collection_id"] == ["does not exist"]
    end
  end

  describe "GET /api/photos" do
    test "lists photos for the signed-in user", %{conn: conn} do
      user = user_fixture()
      photo = photo_fixture(user: user)

      conn =
        conn
        |> auth_json_conn(user)
        |> get(~p"/api/photos")

      response = json_response(conn, 200)
      api_spec = PWeb.ApiSpec.spec()
      assert_schema(response, "PhotoListResponse", api_spec)

      assert length(response["data"]) == 1
      response_photo = List.first(response["data"])
      assert response_photo["id"] == photo.id
      assert response_photo["allowed_to_delete"]
    end
  end

  describe "DELETE /api/photos/:id" do
    test "deletes a photo belonging to the user", %{conn: conn} do
      user = user_fixture()
      photo = photo_fixture(user: user)

      conn =
        conn
        |> auth_json_conn(user)
        |> delete(~p"/api/photos/#{photo.id}")

      assert response(conn, 204)

      refute P.Repo.get(P.Photo, photo.id)
    end

    test "does not allow deleting a photo belonging to another user", %{conn: conn} do
      user = user_fixture()
      other_user = user_fixture()
      photo = photo_fixture(user: other_user)

      conn =
        conn
        |> auth_json_conn(user)
        |> delete(~p"/api/photos/#{photo.id}")

      assert json_response(conn, 404)
      assert P.Repo.get(P.Photo, photo.id)
    end

    test "returns 404 for non-existent photo", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> auth_json_conn(user)
        |> delete(~p"/api/photos/#{Ecto.UUID.generate()}")

      assert json_response(conn, 404)
    end
  end

  describe "photo serialization" do
    test "marks photos as not deletable when the user is not the owner" do
      owner = user_fixture()
      other_user = user_fixture()
      photo = photo_fixture(user: owner)

      summary = PhotoSummary.serialize(photo, current_user: other_user)
      refute summary.allowed_to_delete
    end
  end

  defp local_path(url) do
    uri = URI.parse(url)
    base_dir = Path.expand("../../../priv/waffle/test", __DIR__)

    trimmed_path =
      uri.path
      |> String.trim_leading("/")

    Path.join(base_dir, trimmed_path)
  end
end
