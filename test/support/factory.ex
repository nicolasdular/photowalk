defmodule P.Factory do
  @moduledoc "Test data helpers for succinct fixtures."

  alias P.{Repo, Scope}
  alias P.{Todo, User}

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

  def scope_fixture(attrs \\ %{}) do
    attrs = normalize_attrs(attrs)

    name = Map.get(attrs, :name, :test)
    current_user = Map.get(attrs, :current_user) || Map.get(attrs, :user)
    Scope.new(name: name, current_user: current_user)
  end

  defp normalize_attrs(attrs) when is_list(attrs), do: Map.new(attrs)
  defp normalize_attrs(%{} = attrs), do: attrs
end
