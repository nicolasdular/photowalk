defmodule ThexstackWeb.UserController do
  @moduledoc """
  Controller for user-related API endpoints.

  All endpoints require authentication via the RequireAuth plug.
  """

  use ThexstackWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias ThexstackWeb.Plugs.RequireAuth
  alias OpenApiSpex.Schema

  # Require authentication for all actions in this controller
  plug RequireAuth

  tags(["user"])

  operation(:me,
    summary: "Get current user",
    description: "Returns the currently authenticated user's information",
    responses: [
      ok: {
        "Current user",
        "application/json",
        %Schema{
          type: :object,
          properties: %{
            data: %Schema{
              type: :object,
              properties: %{
                id: %Schema{type: :integer},
                email: %Schema{type: :string, format: :email},
                confirmed_at: %Schema{type: :string, format: :"date-time", nullable: true}
              }
            }
          }
        }
      }
    ]
  )

  def me(conn, _params) do
    user = conn.assigns.current_user

    json(conn, %{
      data: %{
        id: user.id,
        email: user.email,
        confirmed_at: user.confirmed_at
      }
    })
  end
end
