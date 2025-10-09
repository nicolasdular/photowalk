defmodule P.Accounts do
  import Ecto.Query, warn: false

  alias P.{Repo, Scope}
  alias P.{User, MagicLink}
  alias P.Accounts.{Mails.SendMagicLinkEmail}

  @token_max_age 3600
  @allowed_emails ~w(hello@nicolasdular.com hello@philippspiess.com)
  @signature_salt "magic_link_salt"

  @spec get_user(Scope.t(), term()) :: User.t() | nil
  def get_user(%Scope{} = _scope, id) do
    Repo.get(User, id)
  end

  @spec get_user_by_email(Scope.t(), String.t()) :: User.t() | nil
  def get_user_by_email(%Scope{} = _scope, email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @spec request_magic_link(String.t()) :: {:ok, :sent} | {:error, :not_allowed}
  def request_magic_link(email) do
    email = email |> String.trim() |> String.downcase()

    if email in @allowed_emails do
      token = Phoenix.Token.sign(PWeb.Endpoint, @signature_salt, email)

      store_magic_link!(email, token)
      SendMagicLinkEmail.send(email, token)

      {:ok, :sent}
    else
      {:error, :not_allowed}
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
      nil -> insert_user(email, now)
      %User{} = user -> ensure_user_confirmed(user, now)
    end
  end

  defp insert_user(email, now) do
    %User{}
    |> User.changeset(%{email: email, confirmed_at: now})
    |> Repo.insert()
    |> case do
      {:ok, %User{} = user} -> user
      {:error, changeset} -> handle_insert_error(changeset, email, now)
    end
  end

  defp handle_insert_error(changeset, email, now) do
    case Keyword.get(changeset.errors, :email) do
      {"has already been taken", _} ->
        email
        |> fetch_existing_user()
        |> ensure_existing_user(now)

      _ ->
        Repo.rollback(:invalid)
    end
  end

  defp fetch_existing_user(email), do: Repo.get_by(User, email: email)

  defp ensure_existing_user(nil, _now), do: Repo.rollback(:invalid)

  defp ensure_existing_user(%User{} = user, now), do: ensure_user_confirmed(user, now)

  defp ensure_user_confirmed(%User{confirmed_at: nil} = user, now) do
    user
    |> User.changeset(%{confirmed_at: now})
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
end
