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

  # This is a duplicate of the browser pipeline above,
  # but without the plug setting the layout,
  # since we want to set that elsewhere.
  # This could be handled differently,
  # but we're keeping it simple for the example.
  pipeline :custom_domain_browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :custom_domains do
    plug BlogzWeb.CustomDomainsPlug
  end

  # We want to catch any requests for our primary domain in this scope.
  # Nested inside it are the usual scopes and routes for your app.
  # After this, we'll have a scope that catches requests with any other hosts, for custom domains.
  #
  # We're using Phoenix's built in host matcher here, which can take a string or a list of strings.
  # In this case, we're pulling them from the env (set in dev.exs)
  # Unfortunately, we can only use compile time data for this, so we can't set this in runtime.exs.
  # Also note, the host list will also try to use these as prefixes.
  # so if you put www, it will match to www.<anything>.
  #
  # Example primary hosts list: ["www.yourapp.com", "yourapp.com", "localhost"]
  #
  # An easy way to test the custom domain side of things locally, in dev mode:
  # 1. set a blog custom domain as whatever the primary domain is (for instance, localhost)
  # 2. change the host list below to an empty list
  # 3. Reload the "/" route in your browser, it should load the matching blog only now
  scope "/", BlogzWeb, host: Application.compile_env(:blogz, :primary_domains, ["localhost"]) do
    # don't set any pipelines or plugs at this scope level (here),
    # unless you want it to apply to all of them nested inside this.

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

    # The routes that should only be available to authenticated users on the primary domain.
    # These include user settings, CRUD routes for blogs.
    scope "/" do
      pipe_through [:browser, :require_authenticated_user]

      live_session :require_authenticated_user,
        on_mount: [{BlogzWeb.UserAuth, :ensure_authenticated}] do
        live "/users/settings", UserSettingsLive, :edit
        live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

        live "/blogs", BlogLive.Index, :index
        live "/blogs/new", BlogLive.Index, :new
        live "/blogs/:id/edit", BlogLive.Index, :edit

        live "/blogs/:blog_id/posts/new", BlogPostLive.Index, :new
        live "/blogs/:blog_id/posts/:id/edit", BlogPostLive.Index, :edit

        live "/blogs/:blog_id/posts/:id/show/edit", BlogPostLive.Show, :edit
      end
    end

    # This block of routes lets you load a blog and posts by their IDs on
    # the primary domain, with create/edit/delete buttons if logged in.
    # You might not want this in your own app, but it's useful for the example.
    scope "/" do
      pipe_through :browser

      live_session :public_current_user,
        on_mount: [{BlogzWeb.UserAuth, :mount_current_user}] do
        live "/", BlogLive.Index, :index
        live "/blogs/:blog_id", BlogPostLive.Index, :index
        live "/blogs/:blog_id/posts/:post_id", BlogPostLive.Show, :show
      end
    end

    # More default phx.gen.auth routes
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

  # A catch-all scope for any other hosts (custom domains).
  # While all of the other scopes and routes are inside the
  # scope matching the host to the primary domain, we want this
  # to match ANY host, because those will be our custom domains.
  #
  # The :load_blog_for_custom_domain hook will 404 if it doesn't
  # find a matching blog, which is reasonable enough protection against
  # random domains pointing at the app, at least for this example.
  scope "/", BlogzWeb do
    pipe_through [
      # a duplicate of the :browser pipeline, minus the layout plug (set below)
      :custom_domain_browser,
      # a plug that checks for a header or a hostname other than the primary, and
      # sets it in the session as the custom domain.
      :custom_domains
    ]

    live_session :custom_domain_blog, [
      # assigns the custom domain and blog struct to every liveview in this block
      on_mount: [{BlogzWeb.CustomDomainLiveviewHooks, :load_blog_for_custom_domain}],
      # sets the layout to one dedicated to loading the blogs on custom domains
      # Layout module located in blogz_web/components/layouts.ex below the default module
      layout: {BlogzWeb.CustomDomainLayouts, :root}
    ] do
      # The blog index/home page listing posts
      live "/", CustomDomainBlogLive, :index
      # An individual post loaded by post slug
      live "/:post_slug", CustomDomainBlogPostLive, :index
    end
  end
end
