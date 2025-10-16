defmodule PWeb.UserJSON do
  alias P.User

  @fields [:id, :email, :avatar_url, :name]

  def fields, do: @fields

  def show(%{user: user}) do
    %{data: serialize(user)}
  end

  def index(%{users: users}) do
    %{data: Enum.map(users, &serialize/1)}
  end

  def summary(%User{} = user), do: serialize(user)

  def serialize(%User{} = user) do
    user
    |> Map.from_struct()
    |> Map.take(@fields -- [:avatar_url])
    |> Map.put(:avatar_url, User.avatar_url(user))
  end
end
