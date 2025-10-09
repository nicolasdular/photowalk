defmodule PWeb.TodoControllerTest do
  use PWeb.ConnCase, async: true

  import P.Factory
  import OpenApiSpex.TestAssertions

  alias P.{Repo}
  alias P.Todo

  describe "POST /api/todos" do
    setup %{conn: conn} do
      user = user_fixture()
      {:ok, conn: conn, user: user}
    end

    test "creates a todo for the authenticated user", %{conn: conn, user: user} do
      conn =
        conn
        |> auth_json_conn(user)
        |> post(~p"/api/todos", %{"title" => "Finish docs"})

      response = json_response(conn, 201)

      api_spec = PWeb.ApiSpec.spec()
      assert_schema(response, "TodoResponse", api_spec)
      assert %{"data" => %{"id" => id, "title" => "Finish docs"}} = response
      assert Repo.get!(Todo, id).user_id == user.id
    end

    test "returns errors when payload is invalid", %{conn: conn, user: user} do
      conn =
        conn
        |> auth_json_conn(user)
        |> post(~p"/api/todos", %{"title" => nil})

      assert %{"errors" => %{"title" => ["can't be blank"]}} = json_response(conn, 422)
    end

    test "requires authentication", %{conn: conn} do
      conn
      |> json_conn()
      |> post(~p"/api/todos", %{"title" => "Task"})
      |> json_response(401)
    end
  end
end
