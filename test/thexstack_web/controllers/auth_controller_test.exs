defmodule PWeb.AuthControllerTest do
  use PWeb.ConnCase, async: true

  import P.Factory
  import PWeb.TestHelpers
  import Swoosh.TestAssertions

  alias P.Accounts

  describe "POST /api/auth/verify" do
    test "signs the user in with a valid token", %{conn: conn} do
      user = user_fixture(email: "hello@nicolasdular.com", confirmed_at: nil)
      token = request_magic_link_and_capture_token(user.email)

      conn =
        conn
        |> json_conn()
        |> post(~p"/api/auth/verify", %{token: token})

      response = json_response(conn, 200) |> assert_api_spec("Success")

      assert response["success"]
      assert response["message"] == "Signed in"
      assert get_session(conn, :user_id) == user.id
    end

    test "returns unauthorized for an invalid token", %{conn: conn} do
      conn =
        conn
        |> json_conn()
        |> post(~p"/api/auth/verify", %{token: "invalid-token"})

      response = json_response(conn, 401) |> assert_api_spec("Error")

      assert response["error"] ==
               "The magic link is invalid or has expired. Request a new one from the sign-in page."
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
