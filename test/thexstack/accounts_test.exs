defmodule Thexstack.Accounts.MagicLinkTest do
  use Thexstack.DataCase, async: true

  import Swoosh.TestAssertions

  alias Thexstack.Accounts
  alias Thexstack.Accounts.User
  alias Thexstack.Repo

  describe "request_magic_link/1" do
    test "returns error for disallowed email" do
      assert {:error, :not_allowed} = Accounts.request_magic_link("notallowed@example.com")

      refute_email_sent()
    end

    test "sends email with sanitized address when email allowed" do
      email = " Hello@Nicolasdular.com "

      assert {:ok, :sent} = Accounts.request_magic_link(email)

      assert_email_sent(fn sent_email ->
        assert [{_, "hello@nicolasdular.com"}] = sent_email.to
        assert sent_email.html_body =~ "hello@nicolasdular.com"
        assert sent_email.html_body =~ "/auth/"
        true
      end)
    end
  end

  describe "verify_magic_link/1" do
    test "confirms an existing unconfirmed user" do
      email = "hello@nicolasdular.com"
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

    test "creates a user when none exists" do
      email = "hello@nicolasdular.com"
      sanitized_email = String.downcase(String.trim(email))
      assert nil == Repo.get_by(User, email: sanitized_email)

      token = request_magic_link_and_capture_token(email)

      assert {:ok, verified_user} = Accounts.verify_magic_link(token)
      assert verified_user.email == sanitized_email
      refute is_nil(verified_user.confirmed_at)

      assert %User{} = Repo.get_by(User, email: sanitized_email)
    end

    test "returns error when token invalid" do
      assert {:error, :invalid} = Accounts.verify_magic_link("invalid-token")
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
