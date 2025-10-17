defmodule PWeb.SessionControllerTest do
  use PWeb.ConnCase, async: true

  describe "GET /auth/:token" do
    test "redirects to sign-in confirmation page", %{conn: conn} do
      token = "sample-token"

      conn = get(conn, ~p"/auth/#{token}")

      assert redirected_to(conn) == "/confirm/#{token}"
    end
  end
end
