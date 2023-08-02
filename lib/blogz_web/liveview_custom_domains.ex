defmodule BlogzWeb.LiveviewCustomDomains do
  @moduledoc """
  Assigns custom domain if appropriate
  """
  import Phoenix.Component
  alias Blogz.Blogs

  def on_mount(:assign_custom_domain, _params, session, socket) do
    {:cont, assign(socket, :custom_domain, Map.get(session, "custom_domain"))}
  end

  def on_mount(:load_blog_for_custom_domain, _params, session, socket) do
    blog = Blogs.get_blog_by_custom_domain!(Map.get(session, "custom_domain"))
    {
      :cont,
      assign(
        socket,
        %{
          custom_domain: Map.get(session, "custom_domain"),
          blog: blog
        }
      )
    }
  end
end
