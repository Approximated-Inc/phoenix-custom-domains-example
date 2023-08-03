defmodule BlogzWeb.CustomDomainBlogPostLive do
  alias Blogz.BlogPosts
  use BlogzWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class=""><%= @post.title %></div>
    <div class="text-sm mt-1 mb-2 text-gray-500"><%= @post.content %></div>
    """
  end

  def mount(
        %{"post_slug" => post_slug},
        _session,
        socket = %{assigns: %{custom_domain: _custom_domain, blog: blog}}
      ) do
    post = BlogPosts.get_post_by_blog_and_slug(blog.id, post_slug)

    {:ok,
     socket
     |> assign(:post, post)}
  end
end
