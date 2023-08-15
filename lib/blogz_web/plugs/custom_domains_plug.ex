defmodule BlogzWeb.CustomDomainsPlug do
  @behaviour Plug
  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    put_session(conn, :custom_domain, conn.host)
  end
end
