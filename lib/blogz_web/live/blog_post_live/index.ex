defmodule BlogzWeb.BlogPostLive.Index do
  use BlogzWeb, :live_view

  alias Blogz.Blogs
  alias Blogz.BlogPosts
  alias Blogz.BlogPosts.BlogPost

  @impl true
  def mount(%{"blog_id" => blog_id}, _session, socket) do
    blog_posts = BlogPosts.list_blog_posts(String.to_integer(blog_id))
    blog = Blogs.get_blog!(blog_id)

    {
      :ok,
      socket
      |> stream(:blog_posts, blog_posts)
      |> assign(:blog_id, blog_id)
      |> assign(:blog, blog)
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Blog post")
    |> assign(:blog_post, BlogPosts.get_blog_post!(id))
  end

  defp apply_action(socket, :edit_blog, %{"blog_id" => id}) do
    socket
    |> assign(:page_title, "Edit Blog")
    |> assign(:blog, Blogs.get_blog!(id))
    |> assign(:blog_post, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Blog post")
    |> assign(:blog_post, %BlogPost{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Blog posts")
    |> assign(:blog_post, nil)
  end

  @impl true
  def handle_info({BlogzWeb.BlogPostLive.FormComponent, {:saved, blog_post}}, socket) do
    {:noreply, stream_insert(socket, :blog_posts, blog_post)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    blog_post = BlogPosts.get_blog_post!(id)
    {:ok, _} = BlogPosts.delete_blog_post(blog_post)

    {:noreply, stream_delete(socket, :blog_posts, blog_post)}
  end
end
