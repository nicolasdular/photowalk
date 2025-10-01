defmodule ThexstackWeb.Resources.Todo do
  @moduledoc "Single source of truth for Todo API representations and metadata."

  @behaviour ThexstackWeb.Resources.Resource

  alias Thexstack.Tasks.Todo
  alias ThexstackWeb.Resources.Resource

  @impl Resource
  def ecto_schema, do: Todo

  @impl Resource
  def description, do: "A todo item"

  @impl Resource
  def definition do
    %{
      fields: [:id, :title, :completed, :inserted_at, :updated_at],
      required: [:id, :title, :completed, :inserted_at, :updated_at],
      api_only_values: %{},
      api_only_properties: %{},
      example: %{
        id: 1,
        title: "Buy milk",
        completed: false,
        inserted_at: "2024-01-01T12:00:00.000000Z",
        updated_at: "2024-01-01T12:00:00.000000Z"
      }
    }
  end

  def render_one(%Todo{} = todo), do: Resource.render_one(__MODULE__, todo)
  def render_many(todos), do: Resource.render_many(__MODULE__, todos)

  def schema_spec, do: Resource.schema_spec(__MODULE__)
  def collection_response_spec, do: Resource.collection_response_spec(__MODULE__)

  def fields, do: Resource.fields(__MODULE__)
  def required_fields, do: Resource.required_fields(__MODULE__)
  def api_only_values, do: Resource.api_only_values(__MODULE__)
  def api_only_properties, do: Resource.api_only_properties(__MODULE__)
  def example, do: Resource.example(__MODULE__)
end
