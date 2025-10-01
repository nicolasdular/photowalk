defmodule ThexstackWeb.Router do
  use ThexstackWeb, :router

  alias ThexstackWeb.Plugs.Authenticate
  alias ThexstackWeb.Plugs.RequireAuth

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {ThexstackWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Authenticate)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(Authenticate)
    plug(OpenApiSpex.Plug.PutApiSpec, module: ThexstackWeb.ApiSpec)
  end

  pipeline :public_api do
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(OpenApiSpex.Plug.PutApiSpec, module: ThexstackWeb.ApiSpec)
  end

  scope "/" do
    pipe_through(:browser)

    get("/swaggerui", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi")
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:thexstack, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: ThexstackWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end

  scope "/api" do
    pipe_through(:api)

    get("/openapi", OpenApiSpex.Plug.RenderSpec, [])
  end

  scope "/api", ThexstackWeb do
    pipe_through(:public_api)

    # Public auth endpoints
    post("/auth/request-magic-link", AuthController, :request_magic_link)
  end

  scope "/api", ThexstackWeb do
    pipe_through([:api, RequireAuth])

    # Protected API endpoints (require authentication)
    get("/user/me", UserController, :me)

    # Protected Todo endpoints
    get("/todos", TodoController, :index)
    post("/todos", TodoController, :create)
    patch("/todos/:id", TodoController, :update)
    delete("/todos/:id", TodoController, :delete)
  end

  scope "/", ThexstackWeb do
    pipe_through(:api)

    get("/up", HealthController, :up)
  end

  scope "/", ThexstackWeb do
    pipe_through(:browser)

    get("/auth/:token", MagicLinkController, :magic_link)
    delete("/auth/sign_out", SessionController, :delete)

    get("/*path", PageController, :home)
  end
end
