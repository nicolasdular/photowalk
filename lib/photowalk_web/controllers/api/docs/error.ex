defmodule PWeb.Api.Docs.Error do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Error",
    type: :object,
    properties: %{
      error: %Schema{type: :string, description: "Error message"}
    },
    required: [:error],
    example: %{
      error: "Invalid request parameters"
    }
  })
end
