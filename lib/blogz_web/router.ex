defmodule BlogzWeb.Router do
  use BlogzWeb, :router

  import BlogzWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BlogzWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :custom_domains do
    plug BlogzWeb.CustomDomainsPlug
  end

  # We want to catch any requests for our primary domain in this scope.
  # Inside it are the usual scopes and routes for your app.
  # After this, we'll have a scope that catches requests with any other hosts, for custom domains.
  # Example primary hosts list (set in env): ["www.yourapp.com", "yourapp.com", "localhost"]
  scope "/", BlogzWeb, host: Application.get_env(:blogz, :primary_hosts, ["localhost"]) do
    # don't set any pipelines or plugs at this scope level (here),
    # unless you want it to apply to all of them nested inside this.

    scope "/" do
      pipe_through :browser

      get "/", PageController, :home
    end

    # Enable LiveDashboard and Swoosh mailbox preview in development
    if Application.compile_env(:blogz, :dev_routes) do
      # If you want to use the LiveDashboard in production, you should put
      # it behind authentication and allow only admins to access it.
      # If your application does not have an admins-only section yet,
      # you can use Plug.BasicAuth to set up some basic authentication
      # as long as you are also using SSL (which you should anyway).
      import Phoenix.LiveDashboard.Router

      scope "/dev" do
        pipe_through :browser

        live_dashboard "/dashboard", metrics: BlogzWeb.Telemetry
        forward "/mailbox", Plug.Swoosh.MailboxPreview
      end
    end

    ## Default phx.gen.auth routes

    scope "/" do
      pipe_through [:browser, :redirect_if_user_is_authenticated]

      live_session :redirect_if_user_is_authenticated,
        on_mount: [{BlogzWeb.UserAuth, :redirect_if_user_is_authenticated}] do
        live "/users/register", UserRegistrationLive, :new
        live "/users/log_in", UserLoginLive, :new
        live "/users/reset_password", UserForgotPasswordLive, :new
        live "/users/reset_password/:token", UserResetPasswordLive, :edit
      end

      post "/users/log_in", UserSessionController, :create
    end

    scope "/" do
      pipe_through [:browser, :require_authenticated_user]

      live_session :require_authenticated_user,
        on_mount: [{BlogzWeb.UserAuth, :ensure_authenticated}] do
        live "/users/settings", UserSettingsLive, :edit
        live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
      end
    end

    scope "/" do
      pipe_through [:browser]

      delete "/users/log_out", UserSessionController, :delete

      live_session :current_user,
        on_mount: [{BlogzWeb.UserAuth, :mount_current_user}] do
        live "/users/confirm/:token", UserConfirmationLive, :edit
        live "/users/confirm", UserConfirmationInstructionsLive, :new
      end
    end
  end

  # A catch-all scope for any other hosts (custom domains)
  scope "/", BlogzWeb do
    pipe_through [:browser, :custom_domains]
    live_session :custom_domain_blog, on_mount: [{BlogzWeb.LiveviewCustomDomains, :load_blog_by_custom_domain}] do
      live "/", CustomDomainBlogLive, :index
      live "/:post_slug", CustomDomainBlogLive, :index
    end
  end


end
