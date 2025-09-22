defmodule ThexstackWeb.MagicLinkController do
  use ThexstackWeb, :controller

  alias Thexstack.Accounts

  def magic_link(conn, %{"token" => token}) do
    case Accounts.User
         |> Ash.Changeset.for_create(:sign_in_with_magic_link, %{token: token})
         |> Ash.create() do
      {:ok, user} ->
        conn
        |> AshAuthentication.Plug.Helpers.store_in_session(user)
        |> put_flash(:info, "Successfully signed in!")
        |> redirect(to: "/")

      {:error, error} ->
        error_message =
          case error do
            %{errors: errors} when is_list(errors) ->
              errors
              |> Enum.map(&Exception.message/1)
              |> Enum.join(", ")

            _ ->
              "Invalid or expired magic link"
          end

        conn
        |> put_flash(:error, "Failed to sign in: #{error_message}")
        |> redirect(to: "/")
    end
  end
end
