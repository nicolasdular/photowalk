defmodule ThexstackWeb.Schemas.EctoSchema do
  @moduledoc """
  Derives OpenApiSpex schemas from Ecto schemas with selective field exposure.
  """

  defmacro derive_schema(ecto_module, opts \\ []) do
    quote bind_quoted: [ecto_module: ecto_module, opts: opts] do
      alias OpenApiSpex.Schema

      # Only expose fields explicitly listed in :fields option
      selected_fields = Keyword.get(opts, :fields, [])
      additional_properties = Keyword.get(opts, :additional_properties, %{})

      # Build properties from selected Ecto fields
      ecto_properties =
        if selected_fields == [] do
          # If no fields specified, error out - force explicit selection
          raise ArgumentError,
                "Must specify :fields option with list of Ecto fields to expose. " <>
                  "Available fields: #{inspect(ecto_module.__schema__(:fields))}"
        else
          Map.new(selected_fields, fn field_name ->
            unless field_name in ecto_module.__schema__(:fields) do
              raise ArgumentError,
                    "Field #{inspect(field_name)} not found in #{inspect(ecto_module)}. " <>
                      "Available fields: #{inspect(ecto_module.__schema__(:fields))}"
            end

            ecto_type = ecto_module.__schema__(:type, field_name)

            openapi_type =
              ThexstackWeb.Schemas.EctoSchema.map_ecto_type_to_openapi(ecto_type)

            {field_name, openapi_type}
          end)
        end

      # Merge with additional API-only properties
      all_properties = Map.merge(ecto_properties, additional_properties)

      title = opts[:title] || (ecto_module |> Module.split() |> List.last())
      description = opts[:description]
      required = opts[:required] || []
      example = opts[:example]

      schema_opts = %{
        title: title,
        description: description,
        type: :object,
        properties: all_properties,
        required: required
      }

      schema_opts = if example, do: Map.put(schema_opts, :example, example), else: schema_opts

      OpenApiSpex.schema(schema_opts)
    end
  end

  @doc """
  Maps Ecto types to OpenAPI Schema types.
  """
  def map_ecto_type_to_openapi(ecto_type) do
    alias OpenApiSpex.Schema

    case ecto_type do
      :id -> %Schema{type: :integer}
      :integer -> %Schema{type: :integer}
      :string -> %Schema{type: :string}
      :binary -> %Schema{type: :string, format: :binary}
      :boolean -> %Schema{type: :boolean}
      :float -> %Schema{type: :number, format: :float}
      :decimal -> %Schema{type: :number}
      :date -> %Schema{type: :string, format: :date}
      :time -> %Schema{type: :string, format: :time}
      :time_usec -> %Schema{type: :string, format: :time}
      :naive_datetime -> %Schema{type: :string, format: :"date-time"}
      :naive_datetime_usec -> %Schema{type: :string, format: :"date-time"}
      :utc_datetime -> %Schema{type: :string, format: :"date-time"}
      :utc_datetime_usec -> %Schema{type: :string, format: :"date-time"}
      {:array, inner_type} -> %Schema{type: :array, items: map_ecto_type_to_openapi(inner_type)}
      {:map, _} -> %Schema{type: :object}
      _ -> %Schema{type: :string}
    end
  end
end
