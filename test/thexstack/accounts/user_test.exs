defmodule Thexstack.Accounts.UserTest do
  use Thexstack.DataCase, async: true

  alias Thexstack.Accounts
  alias Thexstack.Accounts.User
  alias Thexstack.Repo

  defp valid_email, do: unique_email()
  defp allowed_email, do: "hello@nicolasdular.com"

  describe "get_by_email" do
    test "returns user when email exists" do
      email = valid_email()
      user = user_fixture(%{email: email})

      found_user = Repo.get_by(User, email: email)
      assert found_user.id == user.id
      assert found_user.email == email
    end

    test "returns nil when email doesn't exist" do
      assert nil == Repo.get_by(User, email: "nonexistent@example.com")
    end

    test "email is case insensitive due to citext" do
      email = "Test@Example.com"
      user = user_fixture(%{email: email})

      found_user = Repo.get_by(User, email: "test@example.com")
      assert found_user.id == user.id
    end
  end

  describe "request_magic_link" do
    test "validates email restrictions" do
      # Test with allowed email - should succeed
      email = allowed_email()

      result = Accounts.request_magic_link(email)
      assert {:ok, :sent} = result

      # Test with disallowed email - should fail
      email = "notallowed@example.com"

      result = Accounts.request_magic_link(email)
      assert {:error, :not_allowed} = result
    end
  end

  describe "user attributes" do
    test "has required email attribute" do
      user = user_fixture(%{email: valid_email()})
      assert user.email
      assert is_binary(user.email)
    end

    test "email must be unique" do
      email = valid_email()
      _user1 = user_fixture(%{email: email})

      # Creating another user with same email should fail with changeset error
      assert_raise Ecto.InvalidChangesetError, fn ->
        user_fixture(%{email: email})
      end
    end

    test "has confirmed_at attribute" do
      user = user_fixture(%{email: valid_email()})
      # confirmed_at is optional and might be nil initially
      assert is_nil(user.confirmed_at) or match?(%DateTime{}, user.confirmed_at)
    end
  end

  describe "relationships" do
    test "has_many todos relationship" do
      user = user_fixture(%{email: valid_email()})
      user_with_todos = Repo.preload(user, :todos)
      assert is_list(user_with_todos.todos)
      assert user_with_todos.todos == []
    end
  end
end
