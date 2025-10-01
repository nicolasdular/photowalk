defmodule Thexstack.Accounts do
  @moduledoc """
  The Accounts context.

  Handles user authentication and token management.
  """

  import Ecto.Query, warn: false
  alias Thexstack.Repo
  alias Thexstack.Accounts.{User, Token}

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user by ID.

  Returns `nil` if the User does not exist.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      nil

  """
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Gets a single user by email.

  Returns `nil` if the User does not exist.

  ## Examples

      iex> get_user_by_email("user@example.com")
      %User{}

      iex> get_user_by_email("nonexistent@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{email: "user@example.com"})
      {:ok, %User{}}

      iex> create_user(%{email: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{email: "newemail@example.com"})
      {:ok, %User{}}

      iex> update_user(user, %{email: nil})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Requests a magic link for the given email address.

  Delegates to the MagicLink service module.

  ## Examples

      iex> request_magic_link("user@example.com")
      {:ok, :sent}

      iex> request_magic_link("unauthorized@example.com")
      {:error, :not_allowed}

  """
  defdelegate request_magic_link(email), to: Thexstack.Accounts.MagicLink

  @doc """
  Verifies a magic link token and authenticates the user.

  Delegates to the MagicLink service module.

  ## Examples

      iex> verify_magic_link(valid_token)
      {:ok, %User{}}

      iex> verify_magic_link(invalid_token)
      {:error, :invalid}

  """
  defdelegate verify_magic_link(token), to: Thexstack.Accounts.MagicLink

  @doc """
  Creates an authentication token for a user.

  ## Examples

      iex> create_token(user, "magic_link", %{redirect_to: "/dashboard"})
      {:ok, %Token{}}

  """
  def create_token(%User{} = user, purpose, extra_data \\ %{}) do
    jti = generate_jti()
    expires_at = DateTime.add(DateTime.utc_now(), 3600, :second) # 1 hour default

    attrs = %{
      jti: jti,
      subject: to_string(user.id),
      purpose: purpose,
      expires_at: expires_at,
      extra_data: extra_data
    }

    %Token{}
    |> Token.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a valid (non-expired) token by JTI.

  Returns `nil` if the token does not exist or is expired.

  ## Examples

      iex> get_valid_token("some-jti")
      %Token{}

      iex> get_valid_token("expired-jti")
      nil

  """
  def get_valid_token(jti) when is_binary(jti) do
    Token
    |> where([t], t.jti == ^jti)
    |> where([t], t.expires_at > ^DateTime.utc_now())
    |> Repo.one()
  end

  @doc """
  Deletes a token.

  ## Examples

      iex> delete_token(token)
      {:ok, %Token{}}

  """
  def delete_token(%Token{} = token) do
    Repo.delete(token)
  end

  @doc """
  Deletes all expired tokens.

  Returns the number of deleted tokens.

  ## Examples

      iex> delete_expired_tokens()
      {5, nil}

  """
  def delete_expired_tokens do
    Token
    |> where([t], t.expires_at <= ^DateTime.utc_now())
    |> Repo.delete_all()
  end

  # Private functions

  defp generate_jti do
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64(padding: false)
  end
end
