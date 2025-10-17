defmodule PWeb.AuthController do
  use PWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias P.Accounts
  alias OpenApiSpex.Schema
  alias PWeb.Api.Docs.{Error, Response, Success}

  defmodule MagicLinkVerifyRequest do
    require OpenApiSpex
    alias OpenApiSpex.Schema

    OpenApiSpex.schema(%{
      title: "MagicLinkVerifyRequest",
      description: "Parameters for verifying a magic link",
      type: :object,
      properties: %{
        token: %Schema{type: :string, description: "The magic link token"}
      },
      required: [:token]
    })
  end

  tags(["auth"])

  operation(:request_magic_link,
    request_body: {
      "Input",
      "application/json",
      %Schema{
        type: :object,
        properties: %{
          email: %Schema{type: :string, format: :email, description: "User's email address"}
        },
        required: [:email]
      }
    },
    responses: [
      ok: Response.ok(Success),
      forbidden: Response.forbidden()
    ]
  )

  def request_magic_link(conn, %{"email" => email}) do
    case Accounts.request_magic_link(email) do
      {:ok, :sent} ->
        json(conn, %{success: true, message: "Magic link sent to your email"})

      {:error, :no_account} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Email not found. Please sign up first."})
    end
  end

  operation(:signup,
    request_body: {
      "Email",
      "application/json",
      %Schema{
        type: :object,
        properties: %{
          name: %Schema{type: :string, format: :name},
          email: %Schema{type: :string, format: :email}
        },
        required: [:name, :email]
      }
    },
    responses: [
      ok: Response.ok(Success),
      forbidden: Response.forbidden(),
      conflict: Response.conflict()
    ]
  )

  def signup(conn, %{"email" => email, "name" => name}) do
    case Accounts.signup(email, name) do
      {:ok, :sent} ->
        json(conn, %{success: true, message: "Signup successful. Magic link sent to your email."})

      {:error, :not_allowed} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Email not authorized for signup."})

      {:error, :email_taken} ->
        conn
        |> put_status(:conflict)
        |> json(%{error: "Email already taken."})
    end
  end

  operation(:magic_link_verify,
    summary: "Verify magic link token",
    request_body: {"Magic link verification payload", "application/json", MagicLinkVerifyRequest},
    responses: [
      ok: Response.ok(Success, "Magic link verified"),
      unauthorized: {"Invalid token", "application/json", Error}
    ]
  )

  @doc """
  Verify magic link

  Verifies a magic link token and signs in the user.
  """
  def magic_link_verify(conn, %{"token" => token}) do
    case Accounts.verify_magic_link(token) do
      {:ok, user} ->
        conn
        |> configure_session(renew: true)
        |> put_session(:user_id, user.id)
        |> put_status(:ok)
        |> json(%{success: true, message: "Signed in"})

      {:error, :invalid} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          error: "The magic link is invalid or has expired. Request a new one from the sign-in page."
        })
    end
  end
end
