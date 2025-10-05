defmodule ThexstackWeb.TodoController do
  use ThexstackWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Schema
  alias Thexstack.Tasks
  alias Thexstack.Tasks.Todo
  alias ThexstackWeb.Schemas.EctoSchema

  tags(["todos"])

  @todo_schema EctoSchema.schema_from_fields(Todo,
                description: "A todo item",
                fields: [:id, :title, :completed, :inserted_at, :updated_at],
                additional_properties: %{
                  inserted_at: %Schema{type: :string, description: "Naive ISO8601 timestamp"},
                  updated_at: %Schema{type: :string, description: "Naive ISO8601 timestamp"}
                },
                example: %{
                  "id" => 123,
                  "title" => "Write docs",
                  "completed" => false,
                  "inserted_at" => "2024-01-01T12:00:00",
                  "updated_at" => "2024-01-01T12:05:00"
                }
              )

  @todo_base_params_properties %{
    title: %Schema{type: :string},
    completed: %Schema{type: :boolean, default: false}
  }

  @todo_create_params_schema %Schema{
    title: "TodoCreateParams",
    description: "Attributes for creating a todo",
    type: :object,
    properties: @todo_base_params_properties,
    required: [:title]
  }

  @todo_update_params_schema %Schema{
    title: "TodoUpdateParams",
    description: "Attributes for updating a todo",
    type: :object,
    properties: @todo_base_params_properties
  }

  @todo_response_schema %Schema{
    title: "TodoResponse",
    description: "Response schema for a single todo resource",
    type: :object,
    properties: %{
      data: @todo_schema
    },
    required: [:data]
  }

  @todos_response_schema %Schema{
    title: "TodosResponse",
    description: "Response schema for listing todos",
    type: :object,
    properties: %{
      data: %Schema{type: :array, items: @todo_schema}
    },
    required: [:data]
  }

  operation(:index,
    summary: "List todos for current user",
    description: "Returns all todos belonging to the authenticated user",
    responses: [
      ok: {"Todos response", "application/json", @todos_response_schema}
    ]
  )

  def index(conn, _params) do
    scope = conn.assigns.current_scope
    todos = Tasks.list_todos(scope)

    json(conn, %{data: render_todos(todos)})
  end

  operation(:create,
    summary: "Create a new todo",
    description: "Creates a new todo for the authenticated user",
    request_body: {
      "Todo attributes",
      "application/json",
      @todo_create_params_schema
    },
    responses: [
      created: {"Todo created", "application/json", @todo_response_schema},
      unprocessable_entity: {"Validation errors", "application/json", %Schema{type: :object}}
    ]
  )

  def create(conn, params) do
    scope = conn.assigns.current_scope

    case Tasks.create_todo(scope, params) do
      {:ok, todo} ->
        conn
        |> put_status(:created)
        |> json(%{data: render_todo(todo)})

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
      @todo_update_params_schema
    },
    responses: [
      ok: {"Todo updated", "application/json", @todo_response_schema},
      not_found: {"Todo not found", "application/json", %Schema{type: :object}},
      unprocessable_entity: {"Validation errors", "application/json", %Schema{type: :object}}
    ]
  )

  def update(conn, %{"id" => id} = params) do
    scope = conn.assigns.current_scope

    try do
      todo = Tasks.get_todo!(scope, id)

      case Tasks.update_todo(scope, todo, params) do
        {:ok, updated_todo} ->
          json(conn, %{data: render_todo(updated_todo)})

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

  def todo_schema, do: @todo_schema
  def todo_response_schema, do: @todo_response_schema
  def todos_response_schema, do: @todos_response_schema

  # Private helpers

  defp render_todos(todos), do: Enum.map(todos, &render_todo/1)

  defp render_todo(todo) do
    todo
    |> Map.from_struct()
    |> Map.take([:id, :title, :completed, :inserted_at, :updated_at])
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
