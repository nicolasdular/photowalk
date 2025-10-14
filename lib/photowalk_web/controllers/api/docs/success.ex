defmodule PWeb.Api.Docs.Success do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Success",
    type: :object,
    properties: %{
      success: %Schema{type: :boolean, description: "Indicates if the request was successful"},
      message: %Schema{type: :string, description: "Success message"}
    },
    required: [:success, :message],
    example: %{
      success: true,
      message: "Request was successful"
    }
  })
end
