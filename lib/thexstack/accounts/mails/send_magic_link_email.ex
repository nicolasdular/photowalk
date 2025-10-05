defmodule Thexstack.Accounts.Mails.SendMagicLinkEmail do
  use ThexstackWeb, :verified_routes

  import Swoosh.Email
  alias Thexstack.Mailer

  def send(email, token, _opts \\ nil) do
    new()
    |> from({"noreply", "noreply@" <> email_domain()})
    |> to(to_string(email))
    |> subject("Your login link")
    |> html_body(body(token: token, email: email))
    |> Mailer.deliver!()
  end

  defp body(params) do
    """
    <p>Hello, #{params[:email]}! Click this link to sign in:</p>
    <p><a href="#{url(~p"/auth/#{params[:token]}")}">#{url(~p"/auth/#{params[:token]}")}</a></p>
    """
  end

  defp email_domain do
    System.get_env("EMAIL_DOMAIN") || ThexstackWeb.Endpoint.host()
  end
end
