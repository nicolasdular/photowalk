defmodule ThexstackWeb.Schemas.User do
  @moduledoc "OpenAPI schema for a User resource."

  require OpenApiSpex

  alias ThexstackWeb.Resources.User, as: UserResource

  OpenApiSpex.schema(UserResource.schema_spec())
end
