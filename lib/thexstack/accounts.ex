defmodule Thexstack.Accounts do
  import Ecto.Query, warn: false
  alias Thexstack.{Repo, Scope}
  alias Thexstack.Accounts.{Mails.SendMagicLinkEmail, User}

  @token_max_age 3600
  @allowed_emails ~w(hello@nicolasdular.com hello@philippspiess.com)
  @signature_salt "magic_link_salt"

  def get_user(%Scope{} = _scope, id) do
    Repo.get(User, id)
  end

  def get_user_by_email(%Scope{} = _scope, email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @spec request_magic_link(String.t()) :: {:ok, :sent} | {:error, :not_allowed}
  def request_magic_link(email) do
    email = email |> String.trim() |> String.downcase()

    if email in @allowed_emails do
      token = Phoenix.Token.sign(ThexstackWeb.Endpoint, @signature_salt, email)
      SendMagicLinkEmail.send(email, token)
      {:ok, :sent}
    else
      {:error, :not_allowed}
    end
  end

  @spec verify_magic_link(String.t()) :: {:ok, %User{}} | {:error, :invalid}
  def verify_magic_link(token) do
    with {:ok, email} <-
           Phoenix.Token.verify(ThexstackWeb.Endpoint, @signature_salt, token,
             max_age: @token_max_age
           ),
         user <- Repo.get_by(User, email: email) do
      case user do
        nil ->
          %User{}
          |> User.changeset(%{email: email, confirmed_at: DateTime.utc_now()})
          |> Repo.insert()

        %User{confirmed_at: confirmed_at} = user when not is_nil(confirmed_at) ->
          {:ok, user}

        %User{} = user ->
          user
          |> User.changeset(%{confirmed_at: DateTime.utc_now()})
          |> Repo.update()
      end
    else
      _ -> {:error, :invalid}
    end
  end
end
