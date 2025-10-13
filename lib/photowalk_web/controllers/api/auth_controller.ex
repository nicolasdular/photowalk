defmodule PWeb.AuthController do
  use PWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias P.Accounts
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
end
