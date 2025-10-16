defmodule P.CollectionsTest do
  use P.DataCase, async: true

  import P.Factory

  alias P.Collections

  setup do
    user = user_fixture()
    scope = scope_fixture_with_user(user)
    {:ok, user: user, scope: scope}
  end

  describe "list_collections/1" do
    test "returns collections the user is a member of", %{user: user, scope: scope} do
      other_user = user_fixture()
      collection1 = collection_fixture(user: user, title: "Collection 1")
      collection2 = collection_fixture(user: other_user, title: "Collection 2")
      _other_collection = collection_fixture(user: other_user)

      Collections.add_user(scope_fixture_with_user(other_user), %{
        collection_id: collection2.id,
        user_id: user.id,
        inviter_id: other_user.id
      })

      collections = Collections.list_collections(scope)
      collection_ids = Enum.map(collections, & &1.id)

      assert Enum.sort(collection_ids) == Enum.sort([collection1.id, collection2.id])
    end
  end

  describe "create_collection/2" do
    test "creates a collection with valid attributes", %{user: user, scope: scope} do
      attrs = %{
        "title" => "My Collection",
        "description" => "A test collection"
      }

      assert {:ok, collection} = Collections.create_collection(scope, attrs)
      assert collection.title == "My Collection"
      assert collection.description == "A test collection"
      assert collection.owner_id == user.id
    end

    test "creates a collection without description", %{scope: scope} do
      attrs = %{
        "title" => "My Collection"
      }

      assert {:ok, collection} = Collections.create_collection(scope, attrs)
      assert collection.title == "My Collection"
      assert collection.description == nil
    end

    test "returns error changeset when title is missing", %{scope: scope} do
      attrs = %{
        "description" => "Description only"
      }

      assert {:error, changeset} = Collections.create_collection(scope, attrs)
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "get_collection/2" do
    test "returns collection when user owns it", %{scope: scope, user: user} do
      collection = collection_fixture(user: user)

      assert {:ok, returned_collection} = Collections.get_collection(scope, collection.id)
      assert returned_collection.id == collection.id
    end

    test "returns collection when user is member", %{user: user} do
      collection = collection_fixture(user: user)
      other_user = user_fixture()

      Collections.add_user(scope_fixture_with_user(user), %{
        collection_id: collection.id,
        user_id: other_user.id,
        inviter_id: user.id
      })

      assert {:ok, returned_collection} =
               Collections.get_collection(scope_fixture_with_user(other_user), collection.id)

      assert returned_collection.id == collection.id
    end

    test "returns error when collection belongs to another user", %{scope: scope} do
      other_user = user_fixture()
      collection = collection_fixture(user: other_user)

      assert {:error, :forbidden} = Collections.get_collection(scope, collection.id)
    end

    test "returns error when collection doesn't exist", %{scope: scope} do
      assert {:error, :not_found} =
               Collections.get_collection(scope, Ecto.UUID.generate())
    end
  end

  describe "user_owns_collection?/2" do
    test "returns ok when user owns collection" do
      user = user_fixture()
      collection = collection_fixture(user: user)

      assert {:ok, true} = Collections.user_owns_collection?(user, collection.id)
    end

    test "returns forbidden when collection belongs to another user" do
      user = user_fixture()
      other_user = user_fixture()
      collection = collection_fixture(user: other_user)

      assert {:error, :forbidden} = Collections.user_owns_collection?(user, collection.id)
    end

    test "returns not_found when collection doesn't exist" do
      user = user_fixture()

      assert {:error, :not_found} = Collections.user_owns_collection?(user, Ecto.UUID.generate())
    end
  end

  describe "add_user/1" do
    test "returns the user when adding by email and user exists" do
      owner = user_fixture()
      new_user = user_fixture()
      collection = collection_fixture(user: owner)

      assert {:ok, member} =
               Collections.add_user(scope_fixture_with_user(owner), %{
                 collection_id: collection.id,
                 email: new_user.email,
                 inviter_id: owner.id
               })

      assert member.user_id == new_user.id
    end

    test "adds a member to a collection" do
      owner = user_fixture()
      inviter = user_fixture()
      new_member = user_fixture()
      collection = collection_fixture(user: owner)

      assert {:ok, member} =
               Collections.add_user(scope_fixture_with_user(owner), %{
                 collection_id: collection.id,
                 user_id: new_member.id,
                 inviter_id: inviter.id
               })

      assert member.collection_id == collection.id
      assert member.user_id == new_member.id
      assert member.inviter_id == inviter.id
    end

    test "returns error changeset when adding the same member twice" do
      owner = user_fixture()
      inviter = user_fixture()
      new_member = user_fixture()
      collection = collection_fixture(user: owner)

      assert {:ok, _member} =
               Collections.add_user(scope_fixture_with_user(owner), %{
                 collection_id: collection.id,
                 user_id: new_member.id,
                 inviter_id: inviter.id
               })

      assert {:error, changeset} =
               Collections.add_user(scope_fixture_with_user(owner), %{
                 collection_id: collection.id,
                 user_id: new_member.id,
                 inviter_id: inviter.id
               })

      assert %{user_id: ["is already a member"]} = errors_on(changeset)
    end

    test "returns error when user has no access to the collection", %{user: owner} do
      other_user = user_fixture()
      collection = collection_fixture(user: owner)

      assert {:error, :forbidden} =
               Collections.add_user(scope_fixture_with_user(other_user), %{
                 collection_id: collection.id,
                 user_id: other_user.id,
                 inviter_id: other_user.id
               })
    end
  end

  describe "list_users/2" do
    test "returns members of a collection", %{scope: scope, user: owner} do
      collection = collection_fixture(user: owner)
      member1 = user_fixture()
      member2 = user_fixture()

      Collections.add_user(scope_fixture_with_user(owner), %{
        collection_id: collection.id,
        user_id: member1.id,
        inviter_id: owner.id
      })

      Collections.add_user(scope_fixture_with_user(owner), %{
        collection_id: collection.id,
        user_id: member2.id,
        inviter_id: owner.id
      })

      users = Collections.list_users(scope, collection)
      assert Enum.map(users, & &1.id) == [owner.id, member1.id, member2.id]
    end

    test "returns list when is member", %{scope: scope, user: owner} do
      collection = collection_fixture(user: owner)
      member = user_fixture()

      Collections.add_user(scope_fixture_with_user(owner), %{
        collection_id: collection.id,
        user_id: member.id,
        inviter_id: owner.id
      })

      users = Collections.list_users(scope_fixture_with_user(member), collection)
      assert Enum.sort(Enum.map(users, & &1.id)) == Enum.sort([owner.id, member.id])
    end

    test "returns error when the user has no access" do
      owner = user_fixture()
      other_user = user_fixture()
      collection = collection_fixture(user: owner)

      assert {:error, :forbidden} =
               Collections.list_users(scope_fixture_with_user(other_user), collection)
    end
  end
end
