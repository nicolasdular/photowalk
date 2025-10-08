defmodule ThexstackWeb.UserController do
  use ThexstackWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Schema
  alias Thexstack.User
  alias ThexstackWeb.{Schemas.EctoSchema, UserJSON}

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
                fields: UserJSON.fields()
              )
          },
          required: [:data]
        }
      }
    ]
  )

  def me(conn, _params) do
    user = conn.assigns.current_user

    render(conn, :show, user: user)
  end
end
