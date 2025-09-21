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
    plug :load_from_bearer
    plug :set_actor, :user
  end

  scope "/rpc", ThexstackWeb do
    # or :browser if using session-based auth
    pipe_through(:api)

    post("/run", RpcController, :run)
    post("/validate", RpcController, :validate)
  end

  scope "/", ThexstackWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
    auth_routes AuthController, Thexstack.Accounts.User, path: "/auth"
    sign_out_route AuthController

    # Remove these if you'd like to use your own authentication views
    sign_in_route register_path: "/register",
                  reset_path: "/reset",
                  auth_routes_prefix: "/auth",
                  on_mount: [{ThexstackWeb.LiveUserAuth, :live_no_user}],
                  overrides: [
                    ThexstackWeb.AuthOverrides,
                    AshAuthentication.Phoenix.Overrides.Default
                  ]

    # Remove this if you do not want to use the reset password feature
    reset_route auth_routes_prefix: "/auth",
                overrides: [
                  ThexstackWeb.AuthOverrides,
                  AshAuthentication.Phoenix.Overrides.Default
                ]

    # Remove this if you do not use the confirmation strategy
    confirm_route Thexstack.Accounts.User, :confirm_new_user,
      auth_routes_prefix: "/auth",
      overrides: [ThexstackWeb.AuthOverrides, AshAuthentication.Phoenix.Overrides.Default]

    # Remove this if you do not use the magic link strategy.
    magic_sign_in_route(Thexstack.Accounts.User, :magic_link,
      auth_routes_prefix: "/auth",
      overrides: [ThexstackWeb.AuthOverrides, AshAuthentication.Phoenix.Overrides.Default]
    )
  end

  # Other scopes may use custom stacks.
  # scope "/api", ThexstackWeb do
  #   pipe_through :api
  # end

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
end
