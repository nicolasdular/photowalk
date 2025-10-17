defmodule PWeb.UserControllerTest do
  use PWeb.ConnCase, async: true

  import P.Factory
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

      api_spec = PWeb.ApiSpec.spec()
      assert_schema(response, "SignedInUserResponse", api_spec)
    end

    test "requires authentication", %{conn: conn} do
      conn
      |> json_conn()
      |> get(~p"/api/user/me")
      |> json_response(401)
    end
  end
end
