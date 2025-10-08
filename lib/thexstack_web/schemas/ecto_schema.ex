defmodule ThexstackWeb.Schemas.EctoSchema do
  @moduledoc """
  Derives OpenApiSpex schemas from Ecto schemas with selective field exposure.
  """

  alias OpenApiSpex.Schema

  @doc """
  Builds an `%OpenApiSpex.Schema{}` from the given Ecto schema and list of fields.

  ## Options

    * `:fields` - optional list of fields to expose (defaults to all schema fields)
    * `:title` - optional title for the schema (defaults to module basename)
    * `:description` - optional description
    * `:required` - optional list of required fields (defaults to the provided fields)
    * `:additional_properties` - map of extra or overriding properties
    * `:example` - optional example map for the schema
  """
  @spec schema_from_fields(module(), Keyword.t()) :: Schema.t()
  def schema_from_fields(ecto_module, opts) do
    fields = resolve_fields!(ecto_module, opts)

    properties =
      Enum.reduce(fields, %{}, fn field, acc ->
        ensure_field_exists!(ecto_module, field)

        type = ecto_module.__schema__(:type, field)
        Map.put(acc, field, map_ecto_type_to_openapi(type))
      end)

    additional_properties = Keyword.get(opts, :additional_properties, %{})
    properties = Map.merge(properties, additional_properties)

    required = Keyword.get(opts, :required, fields)
    title = Keyword.get(opts, :title, default_title(ecto_module))
    description = Keyword.get(opts, :description)
    example = Keyword.get(opts, :example)

    schema = %Schema{
      title: title,
      description: description,
      type: :object,
      properties: properties,
      required: required
    }

    if example do
      %{schema | example: example}
    else
      schema
    end
  end

  defp resolve_fields!(ecto_module, opts) do
    if Keyword.has_key?(opts, :fields) do
      fields = Keyword.fetch!(opts, :fields)

      unless is_list(fields) do
        raise ArgumentError, ":fields must be a list, got: #{inspect(fields)}"
      end

      fields
    else
      ecto_module.__schema__(:fields) ++ ecto_module.__schema__(:virtual_fields)
    end
  end

  defp ensure_field_exists!(ecto_module, field) do
    unless field in ecto_module.__schema__(:fields) ||
             field in ecto_module.__schema__(:virtual_fields) do
      raise ArgumentError,
            "Field #{inspect(field)} not found in #{inspect(ecto_module)}. " <>
              "Available fields: #{inspect(ecto_module.__schema__(:fields))}"
    end
  end

  defp default_title(module) do
    module
    |> Module.split()
    |> List.last()
  end

  defp map_ecto_type_to_openapi(ecto_type) do
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
