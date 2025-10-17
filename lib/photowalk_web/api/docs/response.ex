defmodule PWeb.Api.Docs.Response do
  alias PWeb.Api.Docs
  alias OpenApiSpex.Schema

  def forbidden(message \\ nil), do: {message, "application/json", Docs.Error}

  def conflict(message \\ nil), do: {message, "application/json", Docs.Error}

  def ok(schema, message \\ nil), do: {message, "application/json", schema}

  def not_found(message \\ nil),
    do:
      {message, "application/json",
       %Schema{
         title: "NotFoundError",
         type: :object,
         properties: %{
           error: %Schema{type: :string, description: "Error message"}
         },
         required: [:error]
       }}

  def validation_error(description \\ nil) do
    {
      description,
      "application/json",
      %Schema{
        title: "ValidationErrors",
        type: :object,
        properties: %{
          errors: %Schema{
            type: :object,
            additionalProperties: %Schema{type: :array, items: %Schema{type: :string}}
          }
        },
        required: [:errors]
      }
    }
  end

  def data(schema, response_name, description \\ nil) do
    {
      description,
      "application/json",
      %Schema{
        title: response_name,
        type: :object,
        properties: %{
          data: schema
        },
        required: [:data]
      }
    }
  end

  def data_list(schema, response_name, description \\ nil) do
    {
      description,
      "application/json",
      %Schema{
        title: response_name,
        type: :object,
        properties: %{
          data: %Schema{
            type: :array,
            items: schema
          }
        },
        required: [:data]
      }
    }
  end
end
