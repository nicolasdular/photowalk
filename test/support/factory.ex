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
    |> struct!(attrs)
    |> Repo.insert!()
  end

  def todo_fixture(actor, attrs \\ %{}) do
    attrs = Map.merge(%{title: "Test todo", completed: false}, attrs)

    Ash.create!(Todo, attrs, action: :create, actor: actor, domain: Thexstack.Tasks)
  end
end
