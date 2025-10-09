defmodule P.Tasks do
  import Ecto.Query, warn: false
  alias P.{Repo, Scope}
  alias P.{User, Todo}

  def list_todos(%Scope{} = scope) do
    user = ensure_user!(scope, :list_todos)

    Todo
    |> where([t], t.user_id == ^user.id)
    |> order_by([t], desc: t.inserted_at)
    |> order_by([t], desc: t.id)
    |> Repo.all()
  end

  def get_todo!(%Scope{} = scope, id) do
    user = ensure_user!(scope, :get_todo!)

    Todo
    |> where([t], t.id == ^id and t.user_id == ^user.id)
    |> Repo.one!()
  end

  def create_todo(%Scope{} = scope, attrs \\ %{}) do
    user = ensure_user!(scope, :create_todo)

    user
    |> Ecto.build_assoc(:todos)
    |> Todo.changeset(attrs)
    |> Repo.insert()
  end

  def update_todo(%Scope{} = scope, %Todo{} = todo, attrs) do
    ensure_todo_belongs_to_scope!(scope, todo)

    todo
    |> Todo.changeset(attrs)
    |> Repo.update()
  end

  def delete_todo(%Scope{} = scope, %Todo{} = todo) do
    ensure_todo_belongs_to_scope!(scope, todo)
    Repo.delete(todo)
  end

  defp ensure_user!(%Scope{current_user: %User{} = user}, _action), do: user

  defp ensure_user!(%Scope{current_user: nil}, action) do
    raise ArgumentError,
          "scope.current_user is required to invoke #{inspect(action)}"
  end

  defp ensure_todo_belongs_to_scope!(%Scope{} = scope, %Todo{} = todo) do
    user = ensure_user!(scope, :access_todo)

    if todo.user_id != user.id do
      raise ArgumentError, "todo does not belong to scope.current_user"
    end
  end
end
