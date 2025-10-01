defmodule ThexstackWeb.Schemas.Todo do
  @moduledoc "OpenAPI schema for a Todo resource."

  require OpenApiSpex

  alias ThexstackWeb.Resources.Todo, as: TodoResource

  OpenApiSpex.schema(TodoResource.schema_spec())
end
