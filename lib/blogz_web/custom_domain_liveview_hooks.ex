defmodule BlogzWeb.CustomDomainLiveviewHooks do
  @moduledoc """
  On mount hooks for assigning a custom domain if there is one,
  and assigning the appropriate blog if needed.
  """
  import Phoenix.Component
  alias Blogz.Blogs
  alias Blogz.Blogs.Blog

  def on_mount(:load_blog_for_custom_domain, _params, session, socket) do
    # We cache the blog lookup for 5 minutes in ETS,
    # to avoid a db lookup on every mount.
    # You might not want or need to do this in your app,
    # but the struct here is two fields and pretty light on memory.
    # Mostly, this is to show one way you could increase performance.
    blog =
      Blogz.SimpleCache.get(
        Blogs,
        :get_blog_by_custom_domain,
        [Map.get(session, "custom_domain")],
        # 5 mins
        ttl: 300
      )

    case blog do
      %Blog{} = blog ->
        {
          :cont,
          assign(
            socket,
            %{
              custom_domain: Map.get(session, "custom_domain"),
              # for our use case, the blog struct is pretty lightweight
              # so we assign the entire thing. In your use case, you might want to
              # assign just the id and load/stream it as needed in the actual liveview.
              blog: blog
            }
          )
        }

      _ ->
        # This converts to a 404 in phoenix
        raise Ecto.NoResultsError
    end
  end
end
