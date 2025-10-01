defmodule ThexstackWeb.TodoController do
  @moduledoc """
  Controller for todo-related API endpoints.

  All endpoints require authentication via the RequireAuth plug.
  """

  use ThexstackWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Thexstack.Tasks
  alias ThexstackWeb.Resources.Todo, as: TodoResource
  alias ThexstackWeb.Schemas.{Todo, TodoListResponse}
  alias OpenApiSpex.Schema

  tags(["todos"])

  operation(:index,
    summary: "List todos for current user",
    description: "Returns all todos belonging to the authenticated user",
    responses: [
      ok: {"Todos response", "application/json", TodoListResponse}
    ]
  )

  def index(conn, _params) do
    current_user = conn.assigns.current_user
    todos = Tasks.list_todos(current_user)

    json(conn, %{data: TodoResource.render_many(todos)})
  end

  operation(:create,
    summary: "Create a new todo",
    description: "Creates a new todo for the authenticated user",
    request_body: {
      "Todo attributes",
      "application/json",
      %Schema{
        type: :object,
        properties: %{
          title: %Schema{type: :string, description: "Title of the todo"},
          completed: %Schema{type: :boolean, description: "Completion status", default: false}
        },
        required: [:title]
      }
    },
    responses: [
      created: {"Todo created", "application/json", Todo},
      unprocessable_entity: {"Validation errors", "application/json", %Schema{type: :object}}
    ]
  )

  def create(conn, params) do
    current_user = conn.assigns.current_user

    case Tasks.create_todo(current_user, params) do
      {:ok, todo} ->
        conn
        |> put_status(:created)
        |> json(%{data: TodoResource.render_one(todo)})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  operation(:update,
    summary: "Update a todo",
    description: "Updates an existing todo belonging to the authenticated user",
    parameters: [
      id: [in: :path, type: :integer, description: "Todo ID", required: true]
    ],
    request_body: {
      "Todo attributes",
      "application/json",
      %Schema{
        type: :object,
        properties: %{
          title: %Schema{type: :string, description: "Title of the todo"},
          completed: %Schema{type: :boolean, description: "Completion status"}
        }
      }
    },
    responses: [
      ok: {"Todo updated", "application/json", Todo},
      not_found: {"Todo not found", "application/json", %Schema{type: :object}},
      unprocessable_entity: {"Validation errors", "application/json", %Schema{type: :object}}
    ]
  )

  def update(conn, %{"id" => id} = params) do
    current_user = conn.assigns.current_user

    try do
      todo = Tasks.get_todo!(id, current_user)

      case Tasks.update_todo(todo, params) do
        {:ok, updated_todo} ->
          json(conn, %{data: TodoResource.render_one(updated_todo)})

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: format_changeset_errors(changeset)})
      end
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Todo not found"})
    end
  end

  operation(:delete,
    summary: "Delete a todo",
    description: "Deletes an existing todo belonging to the authenticated user",
    parameters: [
      id: [in: :path, type: :integer, description: "Todo ID", required: true]
    ],
    responses: [
      no_content: {"Todo deleted", nil, nil},
      not_found: {"Todo not found", "application/json", %Schema{type: :object}}
    ]
  )

  def delete(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user

    try do
      todo = Tasks.get_todo!(id, current_user)

      case Tasks.delete_todo(todo) do
        {:ok, _deleted_todo} ->
          send_resp(conn, :no_content, "")

        {:error, _changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "Failed to delete todo"})
      end
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Todo not found"})
    end
  end

  # Private helpers

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
