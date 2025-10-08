defmodule ThexstackWeb.TodoController do
  use ThexstackWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias OpenApiSpex.Schema
  alias Thexstack.Tasks
  alias Thexstack.Todo
  alias ThexstackWeb.{Schemas.EctoSchema, TodoJSON}

  tags(["todos"])

  @todo_schema EctoSchema.schema_from_fields(Todo, fields: TodoJSON.fields())

  @todo_base_params_properties %{
    title: %Schema{type: :string},
    completed: %Schema{type: :boolean, default: false}
  }

  operation(:index,
    summary: "List todos for current user",
    responses: [
      ok:
        {"TodosResponse", "application/json",
         %Schema{
           type: :object,
           properties: %{
             data: %Schema{type: :array, items: @todo_schema}
           },
           required: [:data]
         }}
    ]
  )

  def index(conn, _params) do
    scope = conn.assigns.current_scope
    todos = Tasks.list_todos(scope)

    render(conn, :index, todos: todos)
  end

  operation(:create,
    summary: "Create a new todo",
    request_body: {
      "Todo attributes",
      "application/json",
      %Schema{
        type: :object,
        properties: @todo_base_params_properties,
        required: [:title]
      }
    },
    responses: [
      created:
        {"Todo created", "application/json",
         %Schema{
           title: "TodoResponse",
           type: :object,
           properties: %{
             data: @todo_schema
           },
           required: [:data]
         }},
      unprocessable_entity: {"Validation errors", "application/json", %Schema{type: :object}}
    ]
  )

  def create(conn, params) do
    scope = conn.assigns.current_scope

    case Tasks.create_todo(scope, params) do
      {:ok, todo} ->
        conn
        |> put_status(:created)
        |> render(:show, todo: todo)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  operation(:update,
    summary: "Update a todo",
    parameters: [
      id: [in: :path, type: :integer, required: true]
    ],
    request_body: {
      "Todo attributes",
      "application/json",
      %Schema{
        type: :object,
        properties: @todo_base_params_properties
      }
    },
    responses: [
      ok:
        {"Todo updated", "application/json",
         %Schema{
           type: :object,
           properties: %{
             data: @todo_schema
           },
           required: [:data]
         }},
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
          render(conn, :show, todo: updated_todo)

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

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
