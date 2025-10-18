defmodule PWeb.API.Resources.User do
  alias OpenApiSpex.Schema
  alias P.User

  use PWeb.API.Resource

  @fields [:id, :email, :name, :avatar_url]

  @impl true
  def build(%User{} = user, _opts \\ []) do
    Map.take(user, @fields)
    |> Map.put(:avatar_url, avatar_url(user))
  end

  def schema do
    %Schema{
      title: "User",
      description: "A user in the system",
      type: :object,
      required: @fields,
      properties: %{
        id: %Schema{type: :string, format: :uuid},
        email: %Schema{type: :string, format: :email},
        name: %Schema{type: :string},
        avatar_url: %Schema{type: :string, format: :uri}
      }
    }
  end

  defp avatar_url(%User{email: email}) do
    hash =
      :crypto.hash(:md5, String.downcase(String.trim(email)))
      |> Base.encode16(case: :lower)

    "https://www.gravatar.com/avatar/#{hash}"
  end
end
