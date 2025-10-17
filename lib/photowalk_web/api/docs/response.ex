defmodule PWeb.Api.Docs.Response do
  alias PWeb.Api.Docs
  alias OpenApiSpex.Schema

  def forbidden(message \\ nil), do: {message, "application/json", Docs.Error}

  def ok(schema, message \\ nil), do: {message, "application/json", schema}

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
