defmodule PWeb.API.Resources.PhotoDetail do
  alias OpenApiSpex.Schema
  alias P.{Photo, User}
  alias PWeb.API.Resources.PhotoSummary
  alias PWeb.API.Resources.User, as: UserResource

  def schema do
    %Schema{
      title: "PhotoDetail",
      allOf: [
        PhotoSummary.schema(),
        %Schema{
          type: :object,
          required: [:user],
          properties: %{
            user: UserResource.schema()
          }
        }
      ]
    }
  end

  def build(%Photo{} = photo, opts \\ []) do
    %User{} = user = ensure_user_preloaded(photo)
    photo = PhotoSummary.build(photo, opts)

    Map.put(photo, :user, UserResource.build(user))
  end

  defp ensure_user_preloaded(%Photo{user: %User{} = user}), do: user

  defp ensure_user_preloaded(%Photo{}) do
    raise ArgumentError,
          "expected photo.user to be preloaded when building a PhotoDetail resource"
  end
end
