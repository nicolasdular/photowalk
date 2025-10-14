defmodule PWeb.Api.Docs.Response do
  alias PWeb.Api.Docs

  def forbidden(message \\ nil), do: {message, "application/json", Docs.Error}

  def ok(schema, message \\ nil), do: {message, "application/json", schema}
end
