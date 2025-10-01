defmodule Thexstack.Accounts.User.Senders.SendMagicLinkEmail do
  @moduledoc """
  Sends a magic link email
  """

  use ThexstackWeb, :verified_routes

  import Swoosh.Email
  alias Thexstack.Mailer

  @doc """
  Sends a magic link email to the user.

  Accepts either a user struct or an email string.
  """
  def send(user_or_email, token, _opts \\ nil) do
    # if you get a user, its for a user that already exists.
    # if you get an email, then the user does not yet exist.

    email =
      case user_or_email do
        %{email: email} -> email
        email -> email
      end

    new()
    |> from({"noreply", "noreply@" <> email_domain()})
    |> to(to_string(email))
    |> subject("Your login link")
    |> html_body(body(token: token, email: email))
    |> Mailer.deliver!()
  end

  defp body(params) do
    # NOTE: You may have to change this to match your magic link acceptance URL.

    """
    <p>Hello, #{params[:email]}! Click this link to sign in:</p>
    <p><a href="#{url(~p"/auth/#{params[:token]}")}">#{url(~p"/auth/#{params[:token]}")}</a></p>
    """
  end

  defp email_domain do
    case System.get_env("EMAIL_DOMAIN") do
      nil -> "example.com"
      domain -> domain
    end
  end
end
