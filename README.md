### Example repo for adding custom domains to an Elixir Phoenix app

The example is a blog hosting platform, where you can create blogs, blog posts, and connect a custom domain or subdomain to a blog.

**Note**: We use [approximated.app](https://approximated.app) in the example here to handle external routing and SSL management, but most of this could be applied no matter how you handle that.

To start the Phoenix server in development:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

It's recommended that you try this on a publicly accessible server though, so that you can actually test pointing a custom domain/subdomain at a blog.

## The basics of this example

This example app is mostly just a default Phoenix 1.7 app, with a couple of generated contexts for blogs and blog_posts and a few minor changes to those.

A blog in this app has:
- A string field for name
- A string field for custom domain
- A belongs_to assoc for a user
- A has_many assoc for blog_posts
- The standard CRUD liveviews to with a few modifications just for presentation

## Handling Custom Domains

For this example we want to be able to load a blog created here, and only that blog (with it's own layout and everything), on a custom domain that an end user might own.

There's two halves of offering dynamic custom domains as a feature in a web app:

1. Getting the request to your app. 
    - This includes pointing DNS, probably a reverse proxy, and automating SSL certs (not to mention monitoring it all). 
    - This example uses [Approximated.app](https://approximated.app) to handle that all so that we can focus on the second part coming up.
2. Handling requests for custom domains in the app itself.
    - This is what this repo is here to demonstrate

There's a few things that your Phoenix app needs to handle the requests for custom domains:

### Differentiating between the primary domain(s) and custom domains in the router

There's a few ways this can be done, but one of the simplest (and therefore my favorite) is to just wrap all of your app's primary routes in a scope with a hosts matcher, like so:

```elixir
scope "/", BlogzWeb, host: Application.compile_env(:blogz, :primary_domains, ["localhost"]) do
  # don't set any pipelines or plugs at this scope level (here),
  # unless you want it to apply to all of them nested inside this.

  ...routes and even other scopes can be nested in here
end
```

As long as you set your :primary_domains env variable at compile time (or you're on localhost), any request to one of those domains will end up matching inside there.

To catch requests for custom domains, we can have a second scope afterwards (very important it's after the first scope). 

```elixir
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

There's also a few plugs and on_mount hooks here just to conveniently assign the custom domain to the session or liveview, which we'll talk about next.

### Custom domain plugs

In this example repo we have 2 plugs that we use for custom domains. These apply to the connection before any websockets like liveview.

1. [CustomDomainsPlug](lib/blogz_web/plugs/custom_domains_plug.ex)
  - This checks the conn.host and stores it as a session variable `custom_domain` as well, for convenience.
2. [UpdateHostFromHeaderPlug](lib/blogz_web/plugs/update_host_from_header_plug.ex)
  - This checks for a specific header (in our case, `apx-incoming-host`) and replaces the conn.host with it, if it exists.
  - If the header does *not* exist, the conn continues as normal.
  - Here's why:
    - If you have an existing reverse proxy setup, they often won't accept unknown custom domains by default. 
    - Rather than update your reverse proxy, this approach can be much easier to get going.
    - How could a custom domain request have it's host rewritten before hitting your reverse proxy?
      - A service like Approximated can do that automatically, by rewriting the request in-flight.
  - We've placed this plug in endpoint.ex just before the router, so that no matter what, the conn.host is set to the custom domain before hitting the router scopes.

### The on_mount hook
There is an on_mount hook called `:load_blog_for_custom_domain`:
- We call this in the router live_session for the custom domain liveview routes.
- It finds the blog with the matching custom domain and assigns it to the liveview. 
- If it can't find a blog for that custom domain then it will bubble up a not found error, which Phoenix will treat as a 404
- In this example, the blog is just a small struct, in real apps you may want to assign only the ID or handle it in some other way to keep your assigns small.

### Using a different layout for custom domains
In this example, we want the blog to load under the user's custom domain without the primary apps layout.

To do so, we've created a layout specifically for the custom domains, and we set it in the live session like so:

```elixir
layout: {BlogzWeb.CustomDomainLayouts, :root}
```

## Things to know
- This is a simple example, but this approach could be applied to many scenarios besides blogs and blog posts.
- I highly recommend using a service like [approximated.app](https://approximated.app) in front for custom domains, it makes many things, like managing SSL certs, \*much\* easier.
- We need to remember that we're not restricting requests to a single domain, so: 
  - Take any precautions you need for your use case to ensure security for your app.
  - We don't handle this in this example repo, because this will require different approaches according to your app.
  - However, anyone can spoof the host header for any request anyways, and that's all we're dealing with. So there may be nothing extra you need to do.
- Currently, the live_reload websocket is closing early in dev mode when loading from a custom domain.
  - So live_reload won't work when loading from a custom domain in dev mode (which you're probably not doing anyways)
  - This will hopefully be sorted out soon, but it does not affect other websockets like for liveviews.
- There are several liveviews for managing blogs and blog posts on the primary domain
  - They mostly don't matter for this example, we just need them to setup a blog with a custom domain
  - Anything for loading a blog/post with a custom domain is a module prefixed with CustomDomain.


## Files to check out
- [OriginChecks](lib/blogz_web/origin_checks.ex) - Contains the function we provide to our check_origin config, for dynamically checking if a request/websocket domain is allowed.
- [CustomDomainsPlug](lib/blogz_web/plugs/custom_domains_plug.ex) - Sets the `custom_domain` session variable
- [UpdateHostFromHeaderPlug](lib/blogz_web/plugs/update_host_from_header_plug.ex) - Replaces the conn.host with the value from a specific header, if it exists
- [Router](lib/blogz_web/router.ex) - See the host matcher scope for primary domain, and custom domains scope
- [CustomDomainLiveviewHooks](lib/blogz_web/custom_domain_liveview_hooks.ex) - Contains the on_mount hook that assigns the custom domain and blog to the liveviews.
- [CustomDomainBlogLive](lib/blogz_web/live/custom_domain_blog_live.ex) - Liveview that loads the index page for a blog on a custom domain.
- [CustomDomainBlogPostLive](lib/blogz_web/live/custom_domain_blog_post_live.ex) - Liveview that loads a specific blog post by it's slug on a custom domain.
- [Endpoint](lib/blogz_web/endpoint.ex) - Just to note the UpdateHostFromHeaderPlug before the router.

