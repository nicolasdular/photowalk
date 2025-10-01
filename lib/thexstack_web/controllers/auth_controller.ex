defmodule ThexstackWeb.AuthController do
  @moduledoc """
  Controller for authentication endpoints.

  Handles magic link requests and other auth-related actions.
  """

  use ThexstackWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Thexstack.Accounts
  alias OpenApiSpex.Schema

  tags(["auth"])

  operation(:request_magic_link,
    summary: "Request a magic link",
    description: "Sends a magic link to the provided email address for passwordless authentication",
    request_body: {
      "Email",
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
      ok: {
        "Magic link sent",
        "application/json",
        %Schema{
          type: :object,
          properties: %{
            success: %Schema{type: :boolean},
            message: %Schema{type: :string}
          }
        }
      },
      bad_request: {
        "Email is required",
        "application/json",
        %Schema{
          type: :object,
          properties: %{
            error: %Schema{type: :string}
          }
        }
      },
      forbidden: {
        "Email not authorized",
        "application/json",
        %Schema{
          type: :object,
          properties: %{
            error: %Schema{type: :string}
          }
        }
      }
    ]
  )

  def request_magic_link(conn, %{"email" => email}) do
    case Accounts.request_magic_link(email) do
      {:ok, :sent} ->
        json(conn, %{success: true, message: "Magic link sent to your email"})

      {:error, :not_allowed} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Email not authorized"})
    end
  end

  def request_magic_link(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Email is required"})
  end
end
