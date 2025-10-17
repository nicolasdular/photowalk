defmodule PWeb.API.Resources.Helpers do
  @moduledoc false

  @spec datetime_to_iso!(NaiveDateTime.t() | DateTime.t()) :: String.t()
  def datetime_to_iso!(%NaiveDateTime{} = naive) do
    naive
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_iso8601()
  end

  def datetime_to_iso!(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
end
