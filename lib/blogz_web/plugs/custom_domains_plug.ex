defmodule BlogzWeb.CustomDomainsPlug do
  @behaviour Plug
  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    {_, apx_incoming_host} = Enum.find(conn.req_headers, {false, false}, fn {header, _value} -> header == "apx-incoming-host" end)

    # Sometimes we want to pass the custom domain as a header instead of the host,
    # if we have a reverse proxy in front. This checks for a header from Approximated.app,
    # which we're using to route requests and manage SSL certs for custom domains.
    # If there is no header, it uses the conn.host.
    case apx_incoming_host do
      false ->
        put_session(conn, :custom_domain, conn.host)
      _ ->
        put_session(conn, :custom_domain, apx_incoming_host)
    end
  end
end
