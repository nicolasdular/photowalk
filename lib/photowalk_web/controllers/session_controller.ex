defmodule PWeb.SessionController do
  use PWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Schema
  alias PWeb.Api.Docs.{Response, Success}

  tags(["auth"])

  operation(:magic_link_landing,
    summary: "Handle inbound magic link redirect",
    parameters: [
      token: [
        in: :path,
        description: "Magic link token extracted from email URL",
        required: true,
        schema: %Schema{type: :string}
      ]
    ],
    responses: [
      found: {"Redirect to sign-in with token", nil, nil}
    ]
  )

  def magic_link_landing(conn, %{"token" => token}) do
    conn
    |> redirect(to: ~p"/confirm/#{token}")
  end

  operation(:delete,
    summary: "Sign out the current user",
    responses: [
      ok: Response.ok(Success, "Signed out")
    ]
  )

  def delete(conn, _params) do
    conn
    |> clear_session()
    |> put_status(:ok)
    |> json(%{success: true})
  end
end
