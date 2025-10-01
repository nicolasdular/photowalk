defmodule Thexstack.Factory do
  @moduledoc "Test data helpers for succinct fixtures."

  alias Thexstack.{Repo}
  alias Thexstack.Accounts.User
  alias Thexstack.Tasks.Todo

  def unique_email do
    "user-#{System.unique_integer([:positive])}@example.com"
  end

  def user_fixture(attrs \\ %{}) do
    attrs = attrs |> Enum.into(%{email: unique_email()})

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert!()
  end

  def todo_fixture(user, attrs \\ %{}) do
    default_attrs = %{title: "Test todo", completed: false, user_id: user.id}
    attrs = Map.merge(default_attrs, attrs)

    %Todo{}
    |> Todo.changeset(attrs)
    |> Repo.insert!()
  end
end
