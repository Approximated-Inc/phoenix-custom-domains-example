defmodule BlogzWeb.BlogPostLive.Show do
  use BlogzWeb, :live_view

  alias Blogz.BlogPosts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"blog_id" => blog_id, "post_id" => post_id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:blog_id, blog_id)
     |> assign(:blog_post, BlogPosts.get_blog_post!(post_id))}
  end

  defp page_title(:show), do: "Show Blog post"
  defp page_title(:edit), do: "Edit Blog post"
end
