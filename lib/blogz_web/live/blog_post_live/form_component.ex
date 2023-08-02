defmodule BlogzWeb.BlogPostLive.FormComponent do
  use BlogzWeb, :live_component

  alias Blogz.BlogPosts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage blog_post records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="blog_post-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:content]} type="textarea" label="Content" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Blog post</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{blog_post: blog_post} = assigns, socket) do
    changeset = BlogPosts.change_blog_post(blog_post)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"blog_post" => blog_post_params}, socket) do
    changeset =
      socket.assigns.blog_post
      |> BlogPosts.change_blog_post(blog_post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"blog_post" => blog_post_params}, socket) do
    save_blog_post(socket, socket.assigns.action, blog_post_params)
  end

  defp save_blog_post(socket, :edit, blog_post_params) do
    case BlogPosts.update_blog_post(socket.assigns.blog_post, blog_post_params) do
      {:ok, blog_post} ->
        notify_parent({:saved, blog_post})

        {:noreply,
         socket
         |> put_flash(:info, "Blog post updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_blog_post(socket, :new, blog_post_params) do
    case BlogPosts.create_blog_post(socket.assigns.blog_id, socket.assigns.user_id, blog_post_params) do
      {:ok, blog_post} ->
        notify_parent({:saved, blog_post})

        {:noreply,
         socket
         |> put_flash(:info, "Blog post created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
