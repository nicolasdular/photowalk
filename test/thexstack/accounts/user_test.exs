defmodule Thexstack.Accounts.UserTest do
  use Thexstack.DataCase, async: true

  alias Thexstack.Accounts.User

  defp valid_email, do: unique_email()
  defp allowed_email, do: "hello@nicolasdular.com"

  describe "get_by_email action" do
    test "returns user when email exists" do
      email = valid_email()
      user = user_fixture(%{email: email})

      query = User |> Ash.Query.for_read(:get_by_email, %{email: email})
      assert {:ok, found_user} = Ash.read_one(query, authorize?: false)
      assert found_user.id == user.id
      assert Ash.CiString.value(found_user.email) == email
    end

    test "returns nil when email doesn't exist" do
      query = User |> Ash.Query.for_read(:get_by_email, %{email: "nonexistent@example.com"})
      assert {:ok, nil} = Ash.read_one(query, authorize?: false)
    end

    test "is case insensitive" do
      email = "Test@Example.com"
      user = user_fixture(%{email: email})

      query = User |> Ash.Query.for_read(:get_by_email, %{email: "test@example.com"})
      assert {:ok, found_user} = Ash.read_one(query, authorize?: false)
      assert found_user.id == user.id
    end
  end

  describe "current_user action" do
    test "action exists and requires an actor" do
      # Test that the action exists by checking for the proper error when no actor
      query = User |> Ash.Query.for_read(:current_user)
      assert {:error, %Ash.Error.Invalid{}} = Ash.read_one(query)
    end

    test "action filters by actor id when provided" do
      user = user_fixture(%{email: valid_email()})

      assert {:ok, %User{id: returned_id}} =
               User
               |> Ash.Query.for_read(:current_user, %{}, actor: user)
               |> Ash.read_one()

      assert returned_id == user.id
    end
  end

  describe "request_magic_link action" do
    test "action exists and validates email restrictions" do
      # Test with allowed email - should succeed
      email = allowed_email()

      result =
        User
        |> Ash.ActionInput.for_action(:request_magic_link, %{email: email})
        |> Ash.run_action()

      assert :ok = result

      # Test with disallowed email - should fail
      email = "notallowed@example.com"

      result =
        User
        |> Ash.ActionInput.for_action(:request_magic_link, %{email: email})
        |> Ash.run_action()

      assert {:error, error} = result
      assert error.errors
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

      # Creating another user with same email should fail at the database level
      assert_raise Ecto.ConstraintError, fn ->
        user_fixture(%{email: email})
      end
    end

    test "has confirmed_at attribute" do
      user = user_fixture(%{email: valid_email()})
      # confirmed_at is optional and might be nil initially
      assert is_nil(user.confirmed_at) or match?(%DateTime{}, user.confirmed_at)
    end

    test "has avatar_url calculation" do
      user = user_fixture(%{email: valid_email()})
      # Test that avatar_url calculation exists and returns a string
      user_with_avatar = Ash.load!(user, :avatar_url)
      assert is_binary(user_with_avatar.avatar_url)
    end
  end

  describe "relationships" do
    test "has_many todos relationship" do
      user = user_fixture(%{email: valid_email()})
      user_with_todos = Ash.load!(user, :todos)
      assert is_list(user_with_todos.todos)
      assert user_with_todos.todos == []
    end
  end

  describe "authentication actions" do
    test "sign_in_with_magic_link action exists and requires token" do
      # Test that the action exists by checking for proper error when no token provided
      assert {:error, error} =
               Ash.create(User, %{}, action: :sign_in_with_magic_link)

      assert error.errors
      # Should fail due to missing required token argument
      error_messages =
        Enum.map(error.errors, fn err ->
          case err do
            %{reason: reason} -> reason
            %{message: message} -> message
            _ -> ""
          end
        end)

      assert Enum.any?(error_messages, &String.contains?(&1, "token"))
    end

    test "sign_in_with_token action requires token argument" do
      # Test that the action exists by checking it requires a token argument
      action = Ash.Resource.Info.action(User, :sign_in_with_token)

      assert %Ash.Resource.Actions.Read{arguments: arguments} = action

      assert %{name: :token, allow_nil?: false} =
               Enum.find(arguments, &match?(%{name: :token}, &1))
    end
  end
end
