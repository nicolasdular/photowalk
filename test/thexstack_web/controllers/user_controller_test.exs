defmodule ThexstackWeb.UserControllerTest do
  use ThexstackWeb.ConnCase, async: true

  import Thexstack.Factory
  import OpenApiSpex.TestAssertions

  describe "GET /api/user/me" do
    test "returns the authenticated user", %{conn: conn} do
      confirmed_at = DateTime.utc_now() |> DateTime.truncate(:second)
      user = user_fixture(%{email: "jane@example.com", confirmed_at: confirmed_at})

      conn =
        conn
        |> auth_json_conn(user)
        |> get(~p"/api/user/me")

      response = json_response(conn, 200)

      api_spec = ThexstackWeb.ApiSpec.spec()
      assert_schema(response, "UserResponse", api_spec)

      assert %{"data" => %{"id" => id, "email" => email, "confirmed_at" => confirmed_at_string, "avatar_url" => avatar_url}} =
               response

      assert id == user.id
      assert email == user.email

      assert {:ok, parsed_confirmed_at, 0} = DateTime.from_iso8601(confirmed_at_string)
      assert DateTime.compare(parsed_confirmed_at, confirmed_at) == :eq

      expected_hash = :crypto.hash(:md5, user.email) |> Base.encode16(case: :lower)
      assert avatar_url == "https://gravatar.com/avatar/" <> expected_hash
    end

    test "requires authentication", %{conn: conn} do
      conn
      |> json_conn()
      |> get(~p"/api/user/me")
      |> json_response(401)
    end
  end
end
