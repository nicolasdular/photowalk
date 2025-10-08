defmodule ThexstackWeb.UserJSON do
  alias Thexstack.User

  @fields [:id, :email, :avatar_url]

  def fields, do: @fields

  def show(%{user: user}) do
    %{data: serialize(user)}
  end

  def summary(%User{} = user), do: serialize(user)

  defp serialize(%User{} = user) do
    user
    |> Map.from_struct()
    |> Map.take(@fields -- [:avatar_url])
    |> Map.put(:avatar_url, User.avatar_url(user))
  end
end
