defmodule Thexstack.Tasks do
  @moduledoc """
  The Tasks context.

  Handles todo management with proper user authorization.
  """

  import Ecto.Query, warn: false
  alias Thexstack.Repo
  alias Thexstack.Tasks.Todo
  alias Thexstack.Accounts.User

  @doc """
  Returns the list of todos for a specific user.

  ## Examples

      iex> list_todos(user)
      [%Todo{}, ...]

  """
  def list_todos(%User{} = user) do
    Todo
    |> where([t], t.user_id == ^user.id)
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single todo, ensuring it belongs to the specified user.

  Raises `Ecto.NoResultsError` if the Todo does not exist or doesn't belong to the user.

  ## Examples

      iex> get_todo!(123, user)
      %Todo{}

      iex> get_todo!(456, user)
      ** (Ecto.NoResultsError)

  """
  def get_todo!(id, %User{} = user) do
    Todo
    |> where([t], t.id == ^id and t.user_id == ^user.id)
    |> Repo.one!()
  end

  @doc """
  Creates a todo for a user.

  ## Examples

      iex> create_todo(user, %{title: "Buy groceries"})
      {:ok, %Todo{}}

      iex> create_todo(user, %{title: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_todo(%User{} = user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:todos)
    |> Todo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a todo.

  Note: This does not verify user ownership. Use `get_todo!/2` first to ensure
  the todo belongs to the user before updating.

  ## Examples

      iex> update_todo(todo, %{title: "Updated title"})
      {:ok, %Todo{}}

      iex> update_todo(todo, %{title: nil})
      {:error, %Ecto.Changeset{}}

  """
  def update_todo(%Todo{} = todo, attrs) do
    todo
    |> Todo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a todo.

  Note: This does not verify user ownership. Use `get_todo!/2` first to ensure
  the todo belongs to the user before deleting.

  ## Examples

      iex> delete_todo(todo)
      {:ok, %Todo{}}

      iex> delete_todo(todo)
      {:error, %Ecto.Changeset{}}

  """
  def delete_todo(%Todo{} = todo) do
    Repo.delete(todo)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking todo changes.

  ## Examples

      iex> change_todo(todo)
      %Ecto.Changeset{data: %Todo{}}

  """
  def change_todo(%Todo{} = todo, attrs \\ %{}) do
    Todo.changeset(todo, attrs)
  end
end
