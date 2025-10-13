defmodule P.Accounts.MagicLinkTest do
  use P.DataCase, async: true

  import Ecto.Query
  import Swoosh.TestAssertions

  alias P.Accounts
  alias P.MagicLink
  alias P.User
  alias P.Repo

  describe "signup/2" do
    test "creates a new user and sends magic link email" do
      email = "hello@nicolasdular.com"
      name = "New User"

      assert {:ok, :sent} = Accounts.signup(email, name)

      # User is created but not confirmed
      user = Repo.get_by(User, email: email)
      assert user.name == name
      assert user.email == email
      assert is_nil(user.confirmed_at)

      # Email is sent
      assert_email_sent(fn sent_email ->
        assert [{_, ^email}] = sent_email.to
        assert sent_email.html_body =~ email
        assert sent_email.html_body =~ "/auth/"
        true
      end)
    end

    test "sanitizes email address" do
      email = "  Hello@NicolasDular.COM  "
      name = "New User"

      assert {:ok, :sent} = Accounts.signup(email, name)

      sanitized_email = "hello@nicolasdular.com"
      user = Repo.get_by(User, email: sanitized_email)
      assert user.email == sanitized_email

      assert_email_sent(fn sent_email ->
        assert [{_, ^sanitized_email}] = sent_email.to
        true
      end)
    end

    test "trims name" do
      email = "hello@philippspiess.com"
      name = "  John Doe  "

      assert {:ok, :sent} = Accounts.signup(email, name)

      user = Repo.get_by(User, email: email)
      assert user.name == "John Doe"
    end

    test "returns error when email already exists" do
      email = "hello@nicolasdular.com"
      user_fixture(email: email, name: "Existing User")

      assert {:error, :email_taken} = Accounts.signup(email, "Another User")

      refute_email_sent()
    end

    test "returns error when email not allowed" do
      email = "notallowed@example.com"
      name = "Not Allowed User"

      assert {:error, :not_allowed} = Accounts.signup(email, name)

      # User is not created
      assert nil == Repo.get_by(User, email: email)
      refute_email_sent()
    end

    test "returns error changeset when validation fails" do
      assert {:error, changeset} = Accounts.signup("hello@nicolasdular.com", "")
      assert %Ecto.Changeset{} = changeset
      refute changeset.valid?

      refute_email_sent()
    end
  end

  describe "request_magic_link/1" do
    test "returns error for user who does not exist" do
      assert {:error, :no_account} = Accounts.request_magic_link("noaccount@example.com")

      refute_email_sent()
    end

    test "sends email with sanitized address when email allowed" do
      user = user_fixture(email: "Hello@nicolasdular.com")

      assert {:ok, :sent} = Accounts.request_magic_link(user.email)

      assert_email_sent(fn sent_email ->
        assert [{_, "hello@nicolasdular.com"}] = sent_email.to
        assert sent_email.html_body =~ "hello@nicolasdular.com"
        assert sent_email.html_body =~ "/auth/"
        true
      end)
    end
  end

  describe "verify_magic_link/1" do
    test "token can only be used once" do
      user_fixture(email: "hello@nicolasdular.com")
      token = request_magic_link_and_capture_token("hello@nicolasdular.com")

      assert {:ok, %User{}} = Accounts.verify_magic_link(token)
      assert {:error, :invalid} = Accounts.verify_magic_link(token)
    end

    test "confirms an existing unconfirmed user" do
      email = "unconfirmed@example.com"
      user = user_fixture(%{email: email, confirmed_at: nil})
      token = request_magic_link_and_capture_token(email)

      assert {:ok, verified_user} = Accounts.verify_magic_link(token)
      assert verified_user.id == user.id
      refute is_nil(verified_user.confirmed_at)

      reloaded = Repo.get!(User, user.id)
      refute is_nil(reloaded.confirmed_at)
    end

    test "returns confirmed user without changing confirmation timestamp" do
      email = "hello@philippspiess.com"
      confirmed_at = DateTime.utc_now() |> DateTime.truncate(:second)
      user = user_fixture(%{email: email, confirmed_at: confirmed_at})
      token = request_magic_link_and_capture_token(email)

      assert {:ok, verified_user} = Accounts.verify_magic_link(token)
      assert verified_user.id == user.id
      assert DateTime.truncate(verified_user.confirmed_at, :second) == confirmed_at

      reloaded = Repo.get!(User, user.id)
      assert DateTime.truncate(reloaded.confirmed_at, :second) == confirmed_at
    end

    test "returns error when user does not exist" do
      email = "nonexistent@example.com"

      # Create a valid token for a non-existent user
      token = Phoenix.Token.sign(PWeb.Endpoint, "magic_link_salt", email)
      expires_at = DateTime.add(DateTime.utc_now(), 3600, :second)

      %MagicLink{}
      |> MagicLink.changeset(%{
        token_hash: :crypto.hash(:sha256, token),
        email: email,
        expires_at: expires_at
      })
      |> Repo.insert!()

      assert {:error, :invalid} = Accounts.verify_magic_link(token)
      # User should not be created
      assert nil == Repo.get_by(User, email: email)
    end

    test "returns error when token invalid" do
      assert {:error, :invalid} = Accounts.verify_magic_link("invalid-token")
    end

    test "returns error when token expired" do
      email = "token_expired@example.com"

      expired_token =
        Phoenix.Token.sign(PWeb.Endpoint, "magic_link_salt", email,
          signed_at: System.system_time(:second) - 4_000
        )

      assert {:error, :invalid} = Accounts.verify_magic_link(expired_token)
      # User should not be created if token is expired
      assert nil == Repo.get_by(User, email: email)
    end

    test "returns error when magic link expired in storage" do
      email = "storage_expired@example.com"
      user_fixture(email: email)
      token = request_magic_link_and_capture_token(email)

      hashed_token = :crypto.hash(:sha256, token)
      expired_at = DateTime.add(DateTime.utc_now(), -60, :second)

      MagicLink
      |> where([ml], ml.token_hash == ^hashed_token)
      |> Repo.update_all(set: [expires_at: expired_at])

      assert {:error, :invalid} = Accounts.verify_magic_link(token)
      # User still exists but should not be confirmed by expired link
      user = Repo.get_by(User, email: email)
      assert user.email == email
    end

    test "returns error when magic link email differs" do
      email = "email_differs@example.com"
      user_fixture(email: email)
      token = request_magic_link_and_capture_token(email)

      hashed_token = :crypto.hash(:sha256, token)
      mismatched_email = "mismatched@example.com"

      MagicLink
      |> where([ml], ml.token_hash == ^hashed_token)
      |> Repo.update_all(set: [email: mismatched_email])

      assert {:error, :invalid} = Accounts.verify_magic_link(token)
      # Original user still exists
      assert %User{} = Repo.get_by(User, email: email)
      # No user created for mismatched email
      assert nil == Repo.get_by(User, email: mismatched_email)
    end
  end

  defp request_magic_link_and_capture_token(email) do
    assert {:ok, :sent} = Accounts.request_magic_link(email)

    assert_email_sent(fn sent_email ->
      normalized = String.downcase(String.trim(email))
      assert [{_, ^normalized}] = sent_email.to
      assert sent_email.html_body =~ normalized

      extract_token_from_html(sent_email.html_body)
    end)
  end

  defp extract_token_from_html(body) do
    assert [_, token] = Regex.run(~r{/auth/([^"\)]+)}, body)
    token
  end
end
