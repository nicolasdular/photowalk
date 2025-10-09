defmodule PWeb.TodoJSON do
  alias P.Todo

  @fields [:id, :title, :completed, :inserted_at, :updated_at]

  def fields, do: @fields

  def index(%{todos: todos}) do
    %{data: Enum.map(todos, &serialize/1)}
  end

  def show(%{todo: todo}) do
    %{data: serialize(todo)}
  end

  defp serialize(%Todo{} = todo) do
    todo
    |> Map.from_struct()
    |> Map.take(@fields)
    |> format_timestamps([:inserted_at, :updated_at])
  end

  defp format_timestamps(data, keys) do
    Enum.reduce(keys, data, fn key, acc ->
      Map.update(acc, key, nil, &format_datetime/1)
    end)
  end

  defp format_datetime(nil), do: nil
  defp format_datetime(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  defp format_datetime(%NaiveDateTime{} = dt),
    do: DateTime.to_iso8601(DateTime.from_naive!(dt, "Etc/UTC"))
end
