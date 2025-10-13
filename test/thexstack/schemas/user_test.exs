defmodule P.UserTest do
  use P.DataCase, async: true

  defp valid_email, do: unique_email()

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
end
