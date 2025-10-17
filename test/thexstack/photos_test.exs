defmodule P.PhotosTest do
  use P.DataCase, async: true

  import P.Factory

  alias P.Photos

  describe "create_photo/3" do
    test "creates a photo with a collection_id" do
      user = user_fixture()
      scope = scope_fixture(current_user: user)
      collection = collection_fixture(user: user)
      upload = upload_fixture()

      assert {:ok, photo} = Photos.create_photo(scope, upload, %{"collection_id" => collection.id})
      assert photo.collection_id == collection.id
      assert photo.user_id == user.id
    end

    test "creates a photo without a collection_id" do
      user = user_fixture()
      scope = scope_fixture(current_user: user)
      upload = upload_fixture()

      assert {:ok, photo} = Photos.create_photo(scope, upload, %{})
      assert photo.collection_id == nil
      assert photo.user_id == user.id
    end

    test "allows collection members to add photos" do
      owner = user_fixture()
      member = user_fixture()
      collection = collection_fixture(user: owner)
      upload = upload_fixture()

      # Add member to collection
      owner_scope = scope_fixture(current_user: owner)

      {:ok, _} =
        P.Collections.add_user(owner_scope, %{
          collection_id: collection.id,
          user_id: member.id,
          inviter_id: owner.id
        })

      # Member should be able to add photos
      member_scope = scope_fixture(current_user: member)

      assert {:ok, photo} =
               Photos.create_photo(member_scope, upload, %{"collection_id" => collection.id})

      assert photo.collection_id == collection.id
      assert photo.user_id == member.id
    end

    test "rejects photo creation for non-members" do
      user = user_fixture()
      scope = scope_fixture(current_user: user)
      other_user = user_fixture()
      other_collection = collection_fixture(user: other_user)
      upload = upload_fixture()

      assert {:error, changeset} =
               Photos.create_photo(scope, upload, %{"collection_id" => other_collection.id})

      assert %{collection_id: ["you don't have access to this collection"]} = errors_on(changeset)
    end

    test "validates collection exists" do
      user = user_fixture()
      scope = scope_fixture(current_user: user)
      upload = upload_fixture()

      assert {:error, changeset} =
               Photos.create_photo(scope, upload, %{"collection_id" => Ecto.UUID.generate()})

      assert %{collection_id: ["does not exist"]} = errors_on(changeset)
    end

    test "accepts collection_id as atom key" do
      user = user_fixture()
      scope = scope_fixture(current_user: user)
      collection = collection_fixture(user: user)
      upload = upload_fixture()

      assert {:ok, photo} = Photos.create_photo(scope, upload, %{collection_id: collection.id})
      assert photo.collection_id == collection.id
    end
  end

  describe "delete_photo/2" do
    test "deletes the photo and associated files" do
      user = user_fixture()
      photo = photo_fixture(user: user)

      storage_prefix = Application.fetch_env!(:waffle, :storage_dir_prefix)

      base_path =
        Path.join([
          storage_prefix,
          "uploads",
          "users",
          to_string(user.id),
          photo.upload_key
        ])

      full_path = Path.join(base_path, "full.jpg")
      thumb_path = Path.join(base_path, "thumb.jpg")

      assert File.exists?(full_path)
      assert File.exists?(thumb_path)

      assert {:ok, _photo} = Photos.delete_photo(user, photo.id)

      refute File.exists?(full_path)
      refute File.exists?(thumb_path)
    end

    test "returns error when deleting another user's photo" do
      user = user_fixture()
      other_photo = photo_fixture()

      assert {:error, :not_found} = Photos.delete_photo(user, other_photo.id)
      assert Repo.get(P.Photo, other_photo.id)
    end

    test "returns error for unknown photo" do
      user = user_fixture()

      assert {:error, :not_found} = Photos.delete_photo(user, Ecto.UUID.generate())
    end
  end
end
