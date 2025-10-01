defmodule ThexstackWeb.Schemas.UserResponse do
  @moduledoc "OpenAPI schema for the user response payload."

  require OpenApiSpex

  alias ThexstackWeb.Resources.User, as: UserResource

  OpenApiSpex.schema(UserResource.collection_response_spec())
end
