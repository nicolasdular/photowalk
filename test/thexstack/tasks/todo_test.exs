defmodule Thexstack.Tasks.TodoTest do
  use Thexstack.DataCase, async: true

  alias Thexstack.Tasks.Todo

  test "create associates todo to actor and enforces required fields" do
    user = user_fixture()

    todo = todo_fixture(user, %{title: "Write tests"})

    assert %Todo{id: id, title: "Write tests", completed: false} = todo
    assert is_integer(id)
    assert todo.user_id == user.id

    # Invalid: missing title
    assert {:error, %Ash.Error.Invalid{}} = Ash.create(Todo, %{}, action: :create, actor: user)
  end

  test "list returns only current user's todos (policy, pagination)" do
    user1 = user_fixture()
    user2 = user_fixture()

    _ = todo_fixture(user1, %{title: "u1 - a"})
    _ = todo_fixture(user1, %{title: "u1 - b"})
    _ = todo_fixture(user2, %{title: "u2 - a"})

    query = Todo |> Ash.Query.for_read(:list)

    page_for_user1 = Ash.read!(query, actor: user1, page: [limit: 10])
    page_for_user2 = Ash.read!(query, actor: user2, page: [limit: 10])

    titles1 = Enum.map(page_for_user1.results, & &1.title)
    titles2 = Enum.map(page_for_user2.results, & &1.title)

    assert Enum.sort(titles1) == ["u1 - a", "u1 - b"]
    assert Enum.sort(titles2) == ["u2 - a"]
  end

  test "owner can update, others are forbidden" do
    owner = user_fixture()
    other = user_fixture()

    todo = todo_fixture(owner, %{title: "flip me", completed: false})

    # Owner updates successfully
    changeset = todo |> Ash.Changeset.for_update(:update, %{completed: true})
    updated = Ash.update!(changeset, actor: owner)
    assert updated.completed == true

    # Non-owner is forbidden by policies
    changeset2 = todo |> Ash.Changeset.for_update(:update, %{completed: false})
    assert {:error, %Ash.Error.Unknown{errors: errors}} =
             Ash.update(changeset2, actor: other)

    assert Enum.any?(errors, fn
             %Ash.Error.Unknown.UnknownError{error: message} ->
               String.contains?(message, "Ash.Error.Forbidden")
             _ ->
               false
           end)
  end
end
