defmodule Thexstack.Accounts.MagicLink do
  @moduledoc """
  Service module for handling magic link authentication.

  Provides functions to request and verify magic links for passwordless authentication.
  """

  alias Thexstack.Accounts.User
  alias Thexstack.Accounts.User.Senders.SendMagicLinkEmail
  alias Thexstack.Repo

  # Token is valid for 1 hour
  @token_max_age 3600

  # Email allowlist for authentication
  @allowed_emails ["hello@nicolasdular.com", "hello@philippspiess.com"]

  @doc """
  Requests a magic link for the given email address.

  Generates a signed token containing the email and sends it via email.
  Only allowed email addresses can request magic links.

  ## Parameters

    - email: The email address to send the magic link to

  ## Returns

    - {:ok, :sent} if the email was sent successfully
    - {:error, :not_allowed} if the email is not in the allowlist
  """
  def request_magic_link(email) do
    email = String.downcase(String.trim(email))

    unless email in @allowed_emails do
      {:error, :not_allowed}
    else
      # Generate a signed token containing the email
      token = Phoenix.Token.sign(ThexstackWeb.Endpoint, "magic_link", email)

      # Find the user if they exist
      user = Repo.get_by(User, email: email)

      # Send the email (works with both user struct and email string)
      SendMagicLinkEmail.send(user || email, token, nil)

      {:ok, :sent}
    end
  end

  @doc """
  Verifies a magic link token and authenticates the user.

  Verifies the token signature and age, then creates the user if they don't exist,
  or confirms their email if they do exist but haven't confirmed yet.

  ## Parameters

    - token: The signed token from the magic link

  ## Returns

    - {:ok, user} if the token is valid and the user is authenticated
    - {:error, :invalid} if the token is invalid or expired
  """
  def verify_magic_link(token) do
    case Phoenix.Token.verify(ThexstackWeb.Endpoint, "magic_link", token, max_age: @token_max_age) do
      {:ok, email} ->
        # Upsert the user (create if doesn't exist, update if exists)
        user = Repo.get_by(User, email: email)

        user =
          if user do
            # User exists - update confirmed_at if not already confirmed
            if is_nil(user.confirmed_at) do
              user
              |> User.changeset(%{confirmed_at: DateTime.utc_now()})
              |> Repo.update!()
            else
              user
            end
          else
            # User doesn't exist - create new user
            %User{}
            |> User.changeset(%{
              email: email,
              confirmed_at: DateTime.utc_now()
            })
            |> Repo.insert!()
          end

        {:ok, user}

      {:error, _reason} ->
        {:error, :invalid}
    end
  end
end
