defmodule BlogzWeb.BlogLive do
  use BlogzWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>Welcome to <%= @custom_domain %></div>
    """
  end

  def mount(_, _session, socket = %{assigns: %{custom_domain: custom_domain}}) do

    {:ok, socket}
  end

  def mount(_, _session, socket) do
    {:ok, socket}
  end
end
