defmodule ThexstackWeb.TodoControllerTest do
  use ThexstackWeb.ConnCase, async: true

  import Thexstack.Factory

  alias Thexstack.{Repo}
  alias Thexstack.Tasks.Todo

  describe "POST /api/todos" do
    setup %{conn: conn} do
      user = user_fixture()
      {:ok, conn: conn, user: user}
    end

    test "creates a todo for the authenticated user", %{conn: conn, user: user} do
      response =
        conn
        |> auth_json_conn(user)
        |> post(~p"/api/todos", %{"title" => "Finish docs"})
        |> json_response(201)

      assert %{"data" => %{"id" => id, "title" => "Finish docs"}} = response
      assert Repo.get!(Todo, id).user_id == user.id
    end

    test "returns errors when payload is invalid", %{conn: conn, user: user} do
      assert %{"errors" => %{"title" => ["can't be blank"]}} =
               conn
               |> auth_json_conn(user)
               |> post(~p"/api/todos", %{"title" => nil})
               |> json_response(422)
    end

    test "requires authentication", %{conn: conn} do
      conn
      |> json_conn()
      |> post(~p"/api/todos", %{"title" => "Task"})
      |> json_response(401)
    end
  end
end
