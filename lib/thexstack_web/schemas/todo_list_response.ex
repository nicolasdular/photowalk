defmodule ThexstackWeb.Schemas.TodoListResponse do
  @moduledoc "OpenAPI schema for the todos index response payload."

  require OpenApiSpex

  alias ThexstackWeb.Resources.Todo, as: TodoResource

  OpenApiSpex.schema(TodoResource.collection_response_spec())
end
