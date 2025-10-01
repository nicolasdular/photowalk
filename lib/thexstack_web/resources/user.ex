defmodule ThexstackWeb.Resources.User do
  @moduledoc "Single source of truth for User API representations and metadata."

  @behaviour ThexstackWeb.Resources.Resource

  alias OpenApiSpex.Schema
  alias Thexstack.Accounts.User
  alias ThexstackWeb.Resources.Resource

  @impl Resource
  def ecto_schema, do: User

  @impl Resource
  def description, do: "A user account"

  @impl Resource
  def definition do
    %{
      fields: [:id, :email, :confirmed_at],
      required: [:id, :email],
      api_only_values: %{},
      api_only_properties: %{
        avatar_url: %Schema{type: :string, description: "Gravatar URL based on user email", format: :uri}
      },
      example: %{
        id: 1,
        email: "user@example.com",
        confirmed_at: "2024-01-01T12:00:00.000000Z",
        avatar_url: "https://gravatar.com/avatar/b58996c504c5638798eb6b511e6f49af"
      }
    }
  end

  def render_one(%User{} = user) do
    base = Resource.render_one(__MODULE__, user)
    Map.put(base, :avatar_url, compute_avatar_url(user.email))
  end

  def render_many(users), do: Enum.map(users, &render_one/1)

  def schema_spec, do: Resource.schema_spec(__MODULE__)
  def collection_response_spec, do: Resource.collection_response_spec(__MODULE__)

  def fields, do: Resource.fields(__MODULE__)
  def required_fields, do: Resource.required_fields(__MODULE__)
  def api_only_values, do: Resource.api_only_values(__MODULE__)
  def api_only_properties, do: Resource.api_only_properties(__MODULE__)
  def example, do: Resource.example(__MODULE__)

  defp compute_avatar_url(email) do
    email = to_string(email)
    hash = :crypto.hash(:md5, email) |> Base.encode16(case: :lower)
    "https://gravatar.com/avatar/" <> hash
  end
end
