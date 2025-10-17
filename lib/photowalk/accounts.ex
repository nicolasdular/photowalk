defmodule P.Accounts do
  import Ecto.Query, warn: false

  alias P.{Repo, Scope}
  alias P.{User, MagicLink}
  alias P.Accounts.{Mails.SendMagicLinkEmail}

  @token_max_age 3600
  @allowed_emails ~w(hello@nicolasdular.com julia.edlinger@live.at)
  @signature_salt "magic_link_salt"

  @spec get_user_by_email(Scope.t(), String.t()) :: User.t() | nil
  def get_user_by_email(%Scope{} = _scope, email) do
    Repo.get_by(User, email: normalize_email(email))
  end

  @spec signup(String.t(), String.t()) ::
          {:ok, :sent} | {:error, Ecto.Changeset.t() | :not_allowed}
  def signup(email, name) do
    email = normalize_email(email)
    name = String.trim(name)

    if email in @allowed_emails do
      case Repo.get_by(User, email: email) do
        nil ->
          # Create user with unconfirmed status
          %User{}
          |> User.changeset(%{email: email, name: name, confirmed_at: nil})
          |> Repo.insert()
          |> case do
            {:ok, _user} ->
              token = Phoenix.Token.sign(PWeb.Endpoint, @signature_salt, email)
              store_magic_link!(email, token)
              SendMagicLinkEmail.send(email, token)
              {:ok, :sent}

            {:error, changeset} ->
              {:error, changeset}
          end

        _existing_user ->
          {:error, :email_taken}
      end
    else
      {:error, :not_allowed}
    end
  end

  @spec request_magic_link(String.t()) :: {:ok, :sent} | {:error, :not_allowed}
  def request_magic_link(email) do
    email = email |> String.trim() |> String.downcase()

    case Repo.get_by(User, email: email) do
      nil ->
        {:error, :no_account}

      _user ->
        token = Phoenix.Token.sign(PWeb.Endpoint, @signature_salt, email)

        store_magic_link!(email, token)
        SendMagicLinkEmail.send(email, token)

        {:ok, :sent}
    end
  end

  @spec verify_magic_link(String.t()) :: {:ok, %User{}} | {:error, :invalid}
  def verify_magic_link(token) do
    with {:ok, email} <-
           Phoenix.Token.verify(PWeb.Endpoint, @signature_salt, token, max_age: @token_max_age),
         {:ok, %User{} = user} <- consume_magic_link(token, email) do
      {:ok, user}
    else
      _ -> {:error, :invalid}
    end
  end

  defp consume_magic_link(token, email) do
    now = DateTime.utc_now()
    hashed_token = token_hash(token)

    Repo.transaction(fn ->
      magic_link =
        MagicLink
        |> where([ml], ml.token_hash == ^hashed_token)
        |> where([ml], is_nil(ml.used_at))
        |> where([ml], ml.expires_at > ^now)
        |> where([ml], ml.email == ^email)
        |> lock("FOR UPDATE")
        |> Repo.one()

      cond do
        is_nil(magic_link) ->
          Repo.rollback(:invalid)

        true ->
          case Repo.update(MagicLink.changeset(magic_link, %{used_at: now})) do
            {:ok, _updated_link} -> fetch_user_for_email(email, now)
            {:error, _changeset} -> Repo.rollback(:invalid)
          end
      end
    end)
  end

  defp fetch_user_for_email(email, now) do
    case Repo.get_by(User, email: email) do
      nil -> Repo.rollback(:invalid)
      %User{} = user -> ensure_user_confirmed(user, now)
    end
  end

  defp ensure_user_confirmed(%User{confirmed_at: nil} = user, now) do
    user
    |> User.magic_link_changeset(%{confirmed_at: now})
    |> Repo.update()
    |> case do
      {:ok, %User{} = updated_user} -> updated_user
      {:error, _changeset} -> Repo.rollback(:invalid)
    end
  end

  defp ensure_user_confirmed(%User{} = user, _now), do: user

  defp store_magic_link!(email, token) do
    expires_at = DateTime.add(DateTime.utc_now(), @token_max_age, :second)

    %MagicLink{}
    |> MagicLink.changeset(%{
      token_hash: token_hash(token),
      email: email,
      expires_at: expires_at
    })
    |> Repo.insert!()
  end

  defp token_hash(token), do: :crypto.hash(:sha256, token)

  defp normalize_email(email) do
    email
    |> String.trim()
    |> String.downcase()
  end
end
