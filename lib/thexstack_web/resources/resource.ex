defmodule ThexstackWeb.Resources.Resource do
  @moduledoc """
  Shared helpers for describing API resources in a single place and
  deriving renderers plus OpenAPI schema fragments from those
  descriptions.
  """

  alias OpenApiSpex.Schema

  @type definition :: %{
          fields: [atom()],
          required: [atom()],
          example: map(),
          api_only_values: map(),
          api_only_properties: %{optional(atom()) => Schema.t()}
        }

  @callback ecto_schema() :: module()
  @callback description() :: String.t() | nil
  @callback definition() :: definition()

  @spec fields(module()) :: [atom()]
  def fields(module) do
    module.definition()[:fields] || raise "resource definition must include :fields"
  end

  @spec required_fields(module()) :: [atom()]
  def required_fields(module) do
    module.definition()[:required] || fields(module)
  end

  @spec api_only_values(module()) :: map()
  def api_only_values(module) do
    Map.get(module.definition(), :api_only_values, %{})
  end

  @spec api_only_properties(module()) :: %{optional(atom()) => Schema.t()}
  def api_only_properties(module) do
    Map.get(module.definition(), :api_only_properties, %{})
  end

  @spec example(module()) :: map()
  def example(module) do
    module.definition()[:example] || %{}
  end

  @spec render_one(module(), struct()) :: map()
  def render_one(module, struct) do
    struct
    |> Map.from_struct()
    |> Map.take(fields(module))
    |> Map.merge(api_only_values(module))
  end

  @spec render_many(module(), Enumerable.t()) :: [map()]
  def render_many(module, collection) do
    Enum.map(collection, &render_one(module, &1))
  end

  @spec schema_spec(module()) :: map()
  def schema_spec(module) do
    ecto_module = module.ecto_schema()
    description = module.description()

    properties =
      module
      |> fields()
      |> Enum.reduce(%{}, fn field, acc ->
        type = ecto_module.__schema__(:type, field)
        schema_type =
          ThexstackWeb.Schemas.EctoSchema.map_ecto_type_to_openapi(type)

        Map.put(acc, field, schema_type)
      end)

    base = %{
      title: resource_title(module),
      description: description,
      type: :object,
      properties: Map.merge(properties, api_only_properties(module)),
      required: required_fields(module)
    }

    case example(module) do
      example when example == %{} -> base
      example -> Map.put(base, :example, example)
    end
  end

  @spec collection_response_spec(module()) :: map()
  def collection_response_spec(module) do
    %{
      title: "#{resource_title(module)}ListResponse",
      description: "Response schema for listing #{resource_title(module)} resources",
      type: :object,
      properties: %{
        data: %Schema{type: :array, items: schema_as_schema_struct(module)}
      },
      required: [:data],
      example: %{data: [example(module)]}
    }
  end

  @spec schema_as_schema_struct(module()) :: Schema.t()
  defp schema_as_schema_struct(module) do
    spec = schema_spec(module)
    struct(Schema, spec)
  end

  @spec resource_title(module()) :: String.t()
  defp resource_title(module) do
    module
    |> Module.split()
    |> List.last()
  end
end
