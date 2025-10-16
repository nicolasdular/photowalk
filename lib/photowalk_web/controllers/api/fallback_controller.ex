defmodule PWeb.FallbackController do
  use PWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(PWeb.ErrorJSON)
    |> render("422.json", errors: translate_errors(changeset))
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(PWeb.ErrorJSON)
    |> render("404.json")
  end

  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:not_found)
    |> put_view(PWeb.ErrorJSON)
    |> render("404.json")
  end

  def call(conn, {:error, :invalid_id}) do
    conn
    |> put_status(:bad_request)
    |> put_view(PWeb.ErrorJSON)
    |> render("400.json")
  end

  def call(conn, {:error, :user_not_found}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(PWeb.ErrorJSON)
    |> render("422.json", errors: %{email: ["not foundl"]})
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
