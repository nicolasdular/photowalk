defmodule Thexstack.TasksTest do
  use Thexstack.DataCase, async: true

  alias Ecto.Changeset
  alias Thexstack.Tasks
  alias Thexstack.Tasks.Todo

  describe "list_todos/1" do
    test "returns only todos for the given user ordered newest first" do
      user = user_fixture()
      other_user = user_fixture()

      older = todo_fixture(user, %{title: "Older"})
      newer = todo_fixture(user, %{title: "Newer"})
      _ignored = todo_fixture(other_user, %{title: "Ignore me"})

      todos = Tasks.list_todos(user)

      assert MapSet.new(Enum.map(todos, & &1.id)) == MapSet.new([older.id, newer.id])
      assert Enum.sort_by(todos, & &1.inserted_at, &>=/2) == todos
      assert Enum.all?(todos, fn todo -> todo.user_id == user.id end)
    end
  end

  describe "get_todo!/2" do
    test "returns todo owned by the user" do
      user = user_fixture()
      todo = todo_fixture(user)

      assert %Todo{id: id} = Tasks.get_todo!(todo.id, user)
      assert id == todo.id
    end

    test "raises when todo does not belong to the user" do
      owner = user_fixture()
      requester = user_fixture()
      todo = todo_fixture(owner)

      assert_raise Ecto.NoResultsError, fn ->
        Tasks.get_todo!(todo.id, requester)
      end
    end
  end

  describe "create_todo/2" do
    test "creates todo associated to the user when data is valid" do
      user = user_fixture()

      assert {:ok, %Todo{} = todo} = Tasks.create_todo(user, %{"title" => "Write docs"})
      assert todo.user_id == user.id
      refute todo.completed
    end

    test "returns error changeset when data is invalid" do
      user = user_fixture()

      assert {:error, %Changeset{} = changeset} = Tasks.create_todo(user, %{title: nil})
      assert "can't be blank" in errors_on(changeset).title
    end
  end

  describe "update_todo/2" do
    test "updates the todo with valid data" do
      user = user_fixture()
      todo = todo_fixture(user, %{title: "Start", completed: false})

      assert {:ok, %Todo{} = updated} =
               Tasks.update_todo(todo, %{title: "Finish", completed: true})

      assert updated.title == "Finish"
      assert updated.completed
    end

    test "returns error changeset with invalid data" do
      user = user_fixture()
      todo = todo_fixture(user, %{title: "Locked"})

      assert {:error, %Changeset{} = changeset} = Tasks.update_todo(todo, %{title: nil})
      assert "can't be blank" in errors_on(changeset).title

      reloaded = Repo.get!(Todo, todo.id)
      assert reloaded.title == "Locked"
    end
  end

  describe "delete_todo/1" do
    test "removes the todo" do
      user = user_fixture()
      todo = todo_fixture(user)

      assert {:ok, %Todo{}} = Tasks.delete_todo(todo)
      refute Repo.get(Todo, todo.id)
    end
  end

  describe "change_todo/2" do
    test "returns changeset with provided attributes" do
      user = user_fixture()
      todo = todo_fixture(user, %{title: "Original"})

      changeset = Tasks.change_todo(todo, %{title: "Updated"})

      assert %Changeset{data: %Todo{}} = changeset
      assert changeset.changes.title == "Updated"
    end
  end
end
