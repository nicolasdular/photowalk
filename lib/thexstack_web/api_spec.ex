defmodule ThexstackWeb.ApiSpec do
  alias OpenApiSpex.{Components, Info, OpenApi, Paths, Server}
  alias ThexstackWeb.{Endpoint, Router}
  alias ThexstackWeb.Schemas.{Todo, TodoListResponse, User, UserResponse}
  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      servers: servers(),
      info: %Info{title: "Thexstack API", version: "1.0"},
      paths: Paths.from_router(Router),
      components: components()
    }
    |> OpenApiSpex.resolve_schema_modules()
  end

  defp servers do
    try do
      [Server.from_endpoint(Endpoint)]
    rescue
      _ ->
        # Fallback when endpoint is not running (e.g., during spec generation)
        [%Server{url: "http://localhost:4000"}]
    end
  end

  defp components do
    %Components{
      schemas: %{
        Todo: Todo,
        TodosResponse: TodoListResponse,
        User: User,
        UsersResponse: UserResponse
      }
    }
  end
end
