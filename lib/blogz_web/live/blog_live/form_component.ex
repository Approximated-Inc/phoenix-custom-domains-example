defmodule BlogzWeb.BlogLive.FormComponent do
  use BlogzWeb, :live_component

  alias Blogz.Blogs

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage blog records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="blog-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:custom_domain]} type="text" label="Custom domain" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Blog</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{blog: blog} = assigns, socket) do
    changeset = Blogs.change_blog(blog)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"blog" => blog_params}, socket) do
    changeset =
      socket.assigns.blog
      |> Blogs.change_blog(blog_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"blog" => blog_params}, socket) do
    save_blog(socket, socket.assigns.action, blog_params)
  end

  defp save_blog(socket, :edit, blog_params) do
    case Blogs.update_blog(socket.assigns.blog, blog_params) do
      {:ok, blog} ->
        notify_parent({:saved, blog})

        old_cd = socket.assigns.blog.custom_domain

        # Update the Approximated.app virtual host for the custom domain, if there is one.
        # We handle this in a task so that you don't need an account to run this example.
        Task.start(fn ->
          cond do
            # If the blog custom domain was non-nil/empty and now it is nil or empty,
            # delete the Approximated virtual host instead of updating it
            (is_nil(blog.custom_domain) or String.trim(blog.custom_domain) == "") and
                (!is_nil(old_cd) and String.trim(old_cd) != "") ->
              Blogz.Approximated.delete_vhost(old_cd)

            # If the new one is different from the old, update it
            blog.custom_domain != old_cd ->
              Blogz.Approximated.update_vhost(old_cd, blog.custom_domain)

            # Otherwise do nothing (was blank before, is blank now)
            true ->
              nil
          end
        end)

        {:noreply,
         socket
         |> put_flash(:info, "Blog updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_blog(socket, :new, blog_params) do
    case Blogs.create_blog(socket.assigns.user_id, blog_params) do
      {:ok, blog} ->
        notify_parent({:saved, blog})

        # Create an Approximated virtual host to route and secure the custom domain.
        # We handle this in a task so that you don't need an account to run this example.
        unless is_nil(blog.custom_domain) or String.trim(blog.custom_domain) == "" do
          Task.start(fn ->
            Blogz.Approximated.create_vhost(blog.custom_domain)
          end)
        end

        {:noreply,
         socket
         |> put_flash(:info, "Blog created successfully")
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
