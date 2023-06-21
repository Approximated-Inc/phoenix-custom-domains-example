defmodule Blogz.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      BlogzWeb.Telemetry,
      # Start the Ecto repository
      Blogz.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Blogz.PubSub},
      # Start Finch
      {Finch, name: Blogz.Finch},
      # Start the Endpoint (http/https)
      BlogzWeb.Endpoint
      # Start a worker by calling: Blogz.Worker.start_link(arg)
      # {Blogz.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Blogz.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BlogzWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
