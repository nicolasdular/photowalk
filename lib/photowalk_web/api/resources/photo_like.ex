defmodule PWeb.Api.Resources.PhotoLike do
  alias OpenApiSpex.Schema

  def schema do
    %Schema{
      title: "PhotoLike",
      type: :object,
      required: [:users, :count, :current_user_liked],
      properties: %{
        users: %Schema{
          type: :array,
          items: PWeb.API.Resources.User.schema()
        },
        count: %Schema{type: :integer},
        current_user_liked: %Schema{type: :boolean}
      }
    }
  end

  def build(%{likes: likes} = _photo, current_user) do
    users = Enum.map(likes, & &1.user)

    %{
      users: Enum.map(users, &PWeb.API.Resources.User.build/1),
      count: length(users),
      current_user_liked: Enum.any?(users, &(&1.id == current_user.id))
    }
  end
end
