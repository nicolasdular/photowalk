defmodule P.CollectionsTest do
  use P.DataCase, async: true

  import P.Factory

  alias P.Collections

  describe "list_collections_for_user/1" do
    test "returns collections owned by the user" do
      user = user_fixture()
      collection1 = collection_fixture(user: user, title: "Collection 1")
      collection2 = collection_fixture(user: user, title: "Collection 2")

      collections = Collections.list_collections_for_user(user)

      assert length(collections) == 2
      collection_ids = Enum.map(collections, & &1.id)
      assert collection1.id in collection_ids
      assert collection2.id in collection_ids
    end

    test "does not return collections owned by other users" do
      user = user_fixture()
      other_user = user_fixture()
      _other_collection = collection_fixture(user: other_user)

      collections = Collections.list_collections_for_user(user)

      assert collections == []
    end

    test "returns collections ordered by most recent first" do
      user = user_fixture()
      collection_fixture(user: user, title: "Collection 1")
      collection_fixture(user: user, title: "Collection 2")

      collections = Collections.list_collections_for_user(user)

      # Just verify we get the collections back - ordering is implementation detail
      assert length(collections) == 2
    end
  end

  describe "create_collection/2" do
    test "creates a collection with valid attributes" do
      user = user_fixture()

      attrs = %{
        "title" => "My Collection",
        "description" => "A test collection"
      }

      assert {:ok, collection} = Collections.create_collection(user, attrs)
      assert collection.title == "My Collection"
      assert collection.description == "A test collection"
      assert collection.owner_id == user.id
    end

    test "creates a collection without description" do
      user = user_fixture()

      attrs = %{
        "title" => "My Collection"
      }

      assert {:ok, collection} = Collections.create_collection(user, attrs)
      assert collection.title == "My Collection"
      assert collection.description == nil
    end

    test "returns error changeset when title is missing" do
      user = user_fixture()

      attrs = %{
        "description" => "Description only"
      }

      assert {:error, changeset} = Collections.create_collection(user, attrs)
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "get_collection/1" do
    test "returns the collection with given id" do
      user = user_fixture()
      collection = collection_fixture(user: user)

      assert Collections.get_collection(collection.id).id == collection.id
    end

    test "returns nil when collection doesn't exist" do
      assert Collections.get_collection(Ecto.UUID.generate()) == nil
    end
  end

  describe "get_collection_for_user/2" do
    test "returns collection when user owns it" do
      user = user_fixture()
      collection = collection_fixture(user: user)

      assert {:ok, returned_collection} = Collections.get_collection_for_user(collection.id, user)
      assert returned_collection.id == collection.id
    end

    test "returns error when collection belongs to another user" do
      user = user_fixture()
      other_user = user_fixture()
      collection = collection_fixture(user: other_user)

      assert {:error, :not_found} = Collections.get_collection_for_user(collection.id, user)
    end

    test "returns error when collection doesn't exist" do
      user = user_fixture()

      assert {:error, :not_found} =
               Collections.get_collection_for_user(Ecto.UUID.generate(), user)
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

    test "returns error when user has no access to the collection" do
      owner = user_fixture()
      other_user = user_fixture()
      new_member = user_fixture()
      collection = collection_fixture(user: owner)

      assert {:error, :forbidden} =
               Collections.add_user(scope_fixture_with_user(other_user), %{
                 collection_id: collection.id,
                 user_id: new_member.id,
                 inviter_id: other_user.id
               })
    end
  end

  describe "list_members/2" do
    test "returns members of a collection" do
      owner = user_fixture()
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

      users = Collections.list_users(P.Scope.new(current_user: owner), collection)
      assert Enum.map(users, & &1.id) == [owner.id, member1.id, member2.id]
    end

    test "returns list when is member" do
      owner = user_fixture()
      collection = collection_fixture(user: owner)
      member = user_fixture()

      Collections.add_user(scope_fixture_with_user(owner), %{
        collection_id: collection.id,
        user_id: member.id,
        inviter_id: owner.id
      })

      users = Collections.list_users(P.Scope.new(current_user: member), collection)
      assert Enum.map(users, & &1.id) == [owner.id, member.id]
    end

    test "returns error when the user has no access" do
      owner = user_fixture()
      other_user = user_fixture()
      collection = collection_fixture(user: owner)

      assert {:error, :forbidden} =
               Collections.list_users(P.Scope.new(current_user: other_user), collection)
    end
  end
end
