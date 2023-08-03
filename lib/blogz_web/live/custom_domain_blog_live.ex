defmodule BlogzWeb.CustomDomainBlogLive do
  alias Blogz.BlogPosts
  use BlogzWeb, :live_view

  def render(assigns) do
    ~H"""
    <%= for {dom_id, post} <- @streams.blog_posts do %>
      <div id={dom_id} class="pt-4 mt-4 max-w-3xl">
        <div class=""><%= post.title %></div>
        <div class="text-sm mt-1 mb-2 text-gray-500">
          <%= "#{String.slice(post.content, 0..140)}..." %>
        </div>
        <.link class="text-xs text-gray-500 hover:text-gray-800" href={~p"/#{post.slug}"}>
          Read Post
        </.link>
      </div>
    <% end %>
    """
  end

  def mount(_, _session, socket = %{assigns: %{custom_domain: _custom_domain, blog: blog}}) do
    blog_posts = BlogPosts.list_blog_posts(blog.id)

    {:ok,
     socket
     |> stream(:blog_posts, blog_posts)}
  end
end
