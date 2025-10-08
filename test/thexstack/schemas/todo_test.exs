defmodule Thexstack.TodoTest do
  use Thexstack.DataCase, async: true

  alias Thexstack.Tasks
  alias Thexstack.Todo

  test "create associates todo to user and enforces required fields" do
    user = user_fixture()

    todo = todo_fixture(user, %{title: "Write tests"})

    assert %Todo{id: id, title: "Write tests", completed: false} = todo
    assert is_integer(id)
    assert todo.user_id == user.id

    # Invalid: missing title
    changeset = %Todo{} |> Todo.changeset(%{user_id: user.id})
    assert {:error, %Ecto.Changeset{}} = Repo.insert(changeset)
  end

  test "list returns only current user's todos" do
    user1 = user_fixture()
    user2 = user_fixture()
    scope1 = scope_fixture(user: user1)
    scope2 = scope_fixture(user: user2)

    _ = todo_fixture(user1, %{title: "u1 - a"})
    _ = todo_fixture(user1, %{title: "u1 - b"})
    _ = todo_fixture(user2, %{title: "u2 - a"})

    todos_for_user1 = Tasks.list_todos(scope1)
    todos_for_user2 = Tasks.list_todos(scope2)

    titles1 = Enum.map(todos_for_user1, & &1.title)
    titles2 = Enum.map(todos_for_user2, & &1.title)

    assert Enum.sort(titles1) == ["u1 - a", "u1 - b"]
    assert Enum.sort(titles2) == ["u2 - a"]
  end

  test "owner can update their todo" do
    owner = user_fixture()
    scope = scope_fixture(user: owner)

    todo = todo_fixture(owner, %{title: "flip me", completed: false})

    # Owner updates successfully
    assert {:ok, updated} = Tasks.update_todo(scope, todo, %{completed: true})
    assert updated.completed == true
  end
end
