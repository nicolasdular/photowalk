defmodule ThexstackWeb.Router do
  use ThexstackWeb, :router

  use AshAuthentication.Phoenix.Router

  import AshAuthentication.Plug.Helpers

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {ThexstackWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug :load_from_session
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug :load_from_session
    plug :set_actor, :user
  end

  scope "/rpc", ThexstackWeb do
    # or :browser if using session-based auth
    pipe_through(:api)

    post("/run", RpcController, :run)
    post("/validate", RpcController, :validate)
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

  scope "/", ThexstackWeb do
    pipe_through(:browser)

    get("/auth/:token", MagicLinkController, :magic_link)
    delete("/auth/sign_out", SessionController, :delete)

    get("/*path", PageController, :home)
  end
end
