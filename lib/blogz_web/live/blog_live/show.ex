defmodule BlogzWeb.BlogLive.Show do
  use BlogzWeb, :live_view

  alias Blogz.Blogs
  alias Blogz.BlogPosts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :posts, [])}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    blog = Blogs.get_blog!(id)
    posts = BlogPosts.list_blog_posts(blog.id)
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:blog, blog)
     |> stream(:posts, posts)
    }
  end

  defp page_title(:show), do: "Show Blog"
  defp page_title(:edit), do: "Edit Blog"
end
