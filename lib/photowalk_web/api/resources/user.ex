defmodule PWeb.API.Resources.User do
  alias OpenApiSpex.Schema
  alias P.User

  @fields [:id, :email, :name, :avatar_url]

  def serialize(%User{} = user) do
    Map.take(user, @fields) |> Map.put(:avatar_url, User.avatar_url(user))
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
        avatar_url: %Schema{type: :string, format: :uri, nullable: true}
      }
    }
  end
end
