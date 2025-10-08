defmodule ThexstackWeb.AuthController do
  use ThexstackWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Thexstack.Accounts
  alias OpenApiSpex.Schema

  tags(["auth"])

  operation(:request_magic_link,
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
end
