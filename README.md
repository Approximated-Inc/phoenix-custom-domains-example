### Example repo for adding custom domains to an Elixir Phoenix app

The example is a blog hosting platform, where you can create blogs, blog posts, and connect a custom domain or subdomain to a blog.

**Note**: We use [approximated.app](https://approximated.app) in the example here to handle external routing and SSL management, but most of this could be applied no matter how you handle that.

To start the Phoenix server in development:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

It's recommended that you try this on a publicly accessible server though, so that you can actually test pointing a custom domain/subdomain at a blog.

## The basics of this example

This example app is mostly just a default Phoenix 1.7 app:
- It uses phx.gen.auth
- Generated context/schema/LV for Blogs and blog_posts with a few minor changes that don't really matter for learning about custom domains.

For links to the files related directly to implementing custom domains, see the Files to Check Out section at the bottom of this readme.

A blog in this app has:
- A string field for name
- A string field for custom domain
- A belongs_to assoc for a user
- A has_many assoc for blog_posts
- The standard CRUD liveviews to with a few modifications just for presentation

A blog post in this app has:
- A string field for title
- A text field for content
- A belongs_to for user
- A belongs_to for blog
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
    - Rather than update your reverse proxy, you may want the request host to instead be changed to your primary domain (which the reverse proxy already accepts) before it hits your server.
    - How could a custom domain request have it's host rewritten before hitting your reverse proxy?
      - A service like Approximated can do that automatically, by rewriting the request in-flight.
  - We've placed this plug in endpoint.ex just before the router, so that no matter what, the conn.host is set to the custom domain before hitting the router scopes.
  - You can safely remove this plug entirely from your endpoint.ex if you don't want to use this approach.
  - For our example, we keep it because it will work either way

### The on_mount hook
There is an on_mount hook called `:load_blog_for_custom_domain`:
- We call this in the router live_session for the custom domain liveview routes.
- It finds the blog with the matching custom domain and assigns it to the liveview. 
- If it can't find a blog for that custom domain then it will bubble up a not found error, which Phoenix will treat as a 404
- In this example, the blog is just a small struct, in your own app you may want to assign only the ID or handle it in some other way to keep your assigns small.

### Using a different layout for custom domains
In this example, we want the blog to load under the user's custom domain without the primary apps layout.

To do so, we've created a layout specifically for the custom domains, and we set it in the live session like so:

```elixir
layout: {BlogzWeb.CustomDomainLayouts, :root}
```

## Things to know
- This is a simple example, but this approach could be applied to most scenarios, not just blogs and blog posts.
- Highly recommend using a service like [approximated.app](https://approximated.app) in front for custom domains, it makes many things, like managing SSL certs, \*much\* easier.
- We need to remember that we're not restricting requests to a single domain, so: 
  - Make sure to consider any precautions your specific use case might require to ensure security for your app.
  - In this example, we're dynamically checking the origin for http requests and websockets, as well as using CSRF tokens for both.
- There are several liveviews for managing blogs and blog posts on the primary domain
  - They mostly don't matter for this example, we just need them to setup a blog with a custom domain
  - Anything for loading a blog/post with a custom domain is a module prefixed with CustomDomain.

## Known Bugs
- Currently, the live_reload websocket is closing immediately in dev mode if you open the app in the browser from any domain but the primary domain.
  - You're probably not doing that anyways, but just so you're aware
  - It means you'll have to manually reload the page after changes if you're developing this in dev mode, and viewing on a custom domain.
  - It does **not** affect other websocket connections such as channels or liveviews
  - Since live reload isn't used in prod, it's also not an issue there.


## Files to check out
- [OriginChecks](lib/blogz_web/origin_checks.ex) - Contains the function we provide to our check_origin config, for dynamically checking if a request/websocket domain is allowed.
- [CustomDomainsPlug](lib/blogz_web/plugs/custom_domains_plug.ex) - Sets the `custom_domain` session variable
- [UpdateHostFromHeaderPlug](lib/blogz_web/plugs/update_host_from_header_plug.ex) - Replaces the conn.host with the value from a specific header, if it exists
- [Router](lib/blogz_web/router.ex) - See the host matcher scope for primary domain, and custom domains scope
- [CustomDomainLiveviewHooks](lib/blogz_web/custom_domain_liveview_hooks.ex) - Contains the on_mount hook that assigns the custom domain and blog to the liveviews.
- [CustomDomainBlogLive](lib/blogz_web/live/custom_domain_blog_live.ex) - Liveview that loads the index page for a blog on a custom domain.
- [CustomDomainBlogPostLive](lib/blogz_web/live/custom_domain_blog_post_live.ex) - Liveview that loads a specific blog post by it's slug on a custom domain.
- [Endpoint](lib/blogz_web/endpoint.ex) - Just to note the UpdateHostFromHeaderPlug before the router.
- [SimpleCache](lib/blogz/simple_cache.ex) - A module for caching any function results, looked up by the Module-Function-Args combo. 
  - We use this to cache the dynamic origin checks, and to cache the blog struct (only 2 fields) for a few minutes
  - That lets us avoid database lookups for the custom domain on every request, and the blog on every mount
  - This is definitely *not* required, but I wanted to show an easy example for how you *could* optimize for performance.
  - See [Elixir School's ETS post](https://elixirschool.com/en/lessons/storage/ets#example-ets-usage-13) to learn more
- [Approximated](lib/blogz/approximated.ex) - An API client module for [Approximated](https://approximated.app), which we use to automate SSL provisioning.
  - Everything in here runs in a Task.start and we don't care about failures, so that you can test this repo without an Approximated account if you want.
- [Blog FormComponent](lib/blogz_web/live/blog_live/form_component.ex) - For reference on how to add/update/delete an entry on [Approximated](https://approximated.app) when a custom domain is set/changed/removed on a blog.