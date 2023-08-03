defmodule BlogzWeb.BlogLive.Index do
  use BlogzWeb, :live_view

  alias Blogz.Blogs
  alias Blogz.Blogs.Blog

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :blogs, Blogs.list_blogs())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Blog")
    |> assign(:blog, Blogs.get_blog!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Blog")
    |> assign(:blog, %Blog{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Blogs")
    |> assign(:blog, nil)
  end

  @impl true
  def handle_info({BlogzWeb.BlogLive.FormComponent, {:saved, blog}}, socket) do
    {:noreply, stream_insert(socket, :blogs, blog)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    blog = Blogs.get_blog!(id)
    {:ok, _} = Blogs.delete_blog(blog)

    Task.start(fn ->
      unless is_nil(blog.custom_domain) or String.trim(blog.custom_domain) == "" do
        Blogz.Approximated.delete_vhost(blog.custom_domain)
      end
    end)

    {:noreply, stream_delete(socket, :blogs, blog)}
  end
end
