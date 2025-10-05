defmodule ThexstackWeb.UserController do
  @moduledoc """
  Controller for user-related API endpoints.

  All endpoints require authentication via the RequireAuth plug.
  """

  use ThexstackWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Schema
  alias Thexstack.Accounts.User
  alias ThexstackWeb.Plugs.RequireAuth
  alias ThexstackWeb.Schemas.EctoSchema

  # Require authentication for all actions in this controller
  plug(RequireAuth)

  tags(["user"])

  operation(:me,
    summary: "Get current user",
    responses: [
      ok: {
        "Current user",
        "application/json",
        %Schema{
          title: "UserResponse",
          description: "Response schema for a single user",
          type: :object,
          properties: %{
            data:
              EctoSchema.schema_from_fields(User,
                description: "A user account",
                required: [:id, :email],
                additional_properties: %{
                  avatar_url: %Schema{
                    type: :string,
                    format: :uri
                  }
                }
              )
          },
          required: [:data]
        }
      }
    ]
  )

  def me(conn, _params) do
    user = conn.assigns.current_user

    json(conn, %{data: render_user(user)})
  end

  defp render_user(user) do
    %{
      id: user.id,
      email: user.email,
      confirmed_at: user.confirmed_at,
      avatar_url: compute_avatar_url(user.email)
    }
  end

  defp compute_avatar_url(email) do
    email = to_string(email)
    hash = :crypto.hash(:md5, email) |> Base.encode16(case: :lower)
    "https://gravatar.com/avatar/" <> hash
  end
end
