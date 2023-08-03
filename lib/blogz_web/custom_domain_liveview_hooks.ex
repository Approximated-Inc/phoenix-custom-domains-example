defmodule BlogzWeb.CustomDomainLiveviewHooks do
  @moduledoc """
  On mount hooks for assigning a custom domain if there is one,
  and assigning the appropriate blog if needed.
  """
  import Phoenix.Component
  alias Blogz.Blogs

  def on_mount(:assign_custom_domain, _params, session, socket) do
    {:cont, assign(socket, :custom_domain, Map.get(session, "custom_domain"))}
  end

  def on_mount(:load_blog_for_custom_domain, _params, session, socket) do
    # This will return an Ecto.NoResultsError if there's no match,
    # which Phoenix will convert to a 404 response
    blog = Blogs.get_blog_by_custom_domain!(Map.get(session, "custom_domain"))
    {
      :cont,
      assign(
        socket,
        %{
          custom_domain: Map.get(session, "custom_domain"),
          # for our use case, the blog struct is pretty lightweight
          # so we assign the entire thing. In your use case, you might want to
          # assign just the id and load it as needed in the actual liveview.
          blog: blog
        }
      )
    }
  end
end
