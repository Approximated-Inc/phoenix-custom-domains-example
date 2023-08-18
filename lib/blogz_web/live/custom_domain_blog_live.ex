defmodule BlogzWeb.CustomDomainBlogLive do
  alias Blogz.BlogPosts
  use BlogzWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      <p class="hidden only:block">No blog posts yet!</p>
      <%= for {dom_id, post} <- @streams.blog_posts do %>
        <div id={dom_id} class="pt-4 mt-4 max-w-3xl">
          <div class=""><%= post.title %></div>
          <div class="text-sm mt-1 mb-2 text-gray-500">
            <%= "#{String.slice(post.content, 0..140)}..." %>
          </div>
          <.link class="text-xs text-gray-500 hover:text-gray-800" navigate={~p"/#{post.slug}"}>
            Read Post
          </.link>
        </div>
      <% end %>
    </div>

    <div class="mt-8 pt-8 border-t">
      <h3 class="text-lg">Blog Guestbook</h3>
      <p class="text-xs text-gray-500 mb-4">
        This is just here to show that liveview websockets work.<br />
        Names will disappear on reload because we don't save them.
      </p>
      <form id="guest-form" phx-submit="sign guestbook" class="mb-4">
        <input type="text" name="name" class="rounded" />
        <.button>Sign Guestbook</.button>
      </form>
      <%= for guest <- @guests do %>
        <div class="mt-4"><%= guest %></div>
      <% end %>
    </div>
    """
  end

  def mount(_, _session, socket = %{assigns: %{custom_domain: _custom_domain, blog: blog}}) do
    blog_posts = BlogPosts.list_blog_posts(blog.id)

    {:ok,
     socket
     |> stream(:blog_posts, blog_posts)
     |> assign(:guests, [])}
  end

  def handle_event("sign guestbook", %{"name" => name}, socket) do
    {:noreply,
     socket
     |> assign(:guests, [name | socket.assigns.guests])}
  end
end
