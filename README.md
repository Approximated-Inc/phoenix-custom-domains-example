### This is an example repo for how to add custom domains as a feature to a Phoenix app

The example is a blog hosting platform, where you can create blogs, blog posts, and connect a custom domain or subdomain to a blog.

To start the Phoenix server in development:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

It's recommended that you try this on a publicly accessible server though, so that you can actually test pointing a custom domain/subdomain at a blog.

## The basics

This example app is mostly just a default Phoenix 1.7 app, with a couple of generated contexts for blogs and blog_posts and a few minor changes to those.

A blog in this app has:
- A string field for name
- A string field for custom domain
- A belongs_to assoc for a user
- A has_many assoc for blog_posts
- The standard CRUD liveviews to with a few modifications just for presentation

## Where custom domains come in

We want to be able to load a blog created here, and only that blog (with it's own layout and everything), on a custom domain that an end user might own.

There's two halves of offering dynamic custom domains as a feature in a web app:

1. Getting the request to your app. 
    - This includes pointing DNS, probably a reverse proxy, and automating SSL certs (not to mention monitoring it all). 
    - This example uses [Approximated.app](https://approximated.app) to handle that all so that we can focus on the second part coming up.
2. Handling requests for custom domains in the app itself.
    - This is what this repo is here to demonstrate

There's a few things that your Phoenix app needs to handle the requests for custom domains:

### Differentiating between the primary domain(s) and custom domains in the router

There's a few ways this can be done, but one of the simplest (and therefore my favorite) is to just wrap all of your app's primary routes in a scope with a hosts matcher, like so:

```
scope "/", BlogzWeb, host: Application.compile_env(:blogz, :primary_domains, ["localhost"]) do
  # don't set any pipelines or plugs at this scope level (here),
  # unless you want it to apply to all of them nested inside this.

  ...routes and even other scopes can be nested in here
end
```

As long as you set your :primary_domains env variable (or you're on localhost), any request to one of those domains will end up matching inside there.

To catch requests for custom domains, we can have a second scope afterwards (very important it's after the first scope). There's also a few plugs and on_mount hooks here just to conveniently assign the custom domain to the session or liveview:

```
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
```