defmodule P.PhotosTest do
  use P.DataCase, async: true

  import P.Factory

  alias P.Photos

  describe "create_photo/3" do
    test "creates a photo with a collection_id" do
      user = user_fixture()
      collection = collection_fixture(user: user)
      upload = upload_fixture()

      assert {:ok, photo} = Photos.create_photo(user, upload, %{"collection_id" => collection.id})
      assert photo.collection_id == collection.id
      assert photo.user_id == user.id
    end

    test "creates a photo without a collection_id" do
      user = user_fixture()
      upload = upload_fixture()

      assert {:ok, photo} = Photos.create_photo(user, upload, %{})
      assert photo.collection_id == nil
      assert photo.user_id == user.id
    end

    test "validates collection belongs to user" do
      user = user_fixture()
      other_user = user_fixture()
      other_collection = collection_fixture(user: other_user)
      upload = upload_fixture()

      assert {:error, changeset} =
               Photos.create_photo(user, upload, %{"collection_id" => other_collection.id})

      assert %{collection_id: ["does not belong to you"]} = errors_on(changeset)
    end

    test "validates collection exists" do
      user = user_fixture()
      upload = upload_fixture()

      assert {:error, changeset} = Photos.create_photo(user, upload, %{"collection_id" => 99999})
      assert %{collection_id: ["does not exist"]} = errors_on(changeset)
    end

    test "accepts collection_id as atom key" do
      user = user_fixture()
      collection = collection_fixture(user: user)
      upload = upload_fixture()

      assert {:ok, photo} = Photos.create_photo(user, upload, %{collection_id: collection.id})
      assert photo.collection_id == collection.id
    end
  end
end
