defmodule BlogzWeb.UpdateHostFromApxHeaderPlug do
  @moduledoc """
  Sometimes we want to:
  1. Put a reverse proxy in front of everything
  2. Replace the custom domain host header (theirdomain.com) with the app's primary domain (yourapp.com)
  3. Pass the custom domain as different header, which the app can use to differentiate primary from custom domains

  Why?
  This can *really* simplify things when you have an existing setup
  that will break if you add arbitrary hosts into the mix.

  For example, if you have reverse proxies, load balancers, etc. in front of your app,
  then you probably don't want to have to reconfigure them more than necessary.

  With this approach, every custom domain request will seem like a regular request to your app,
  and your app can sort out what to return based on the header.

  In this example, this plug checks for a header from Approximated.app,
  which we're using to reverse proxy requests and manage SSL certs for custom domains.
  If there is no header, the conn just continues on as usual.
  We'll want to put this in the endpoint.ex file as a plug, just before the router.

  This plug will *also* work if you don't use this the separate header approach, so no harm to have it.
  """
  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    {_, apx_incoming_host} = Enum.find(conn.req_headers, {false, false}, fn {header, _value} -> header == "apx-incoming-host" end)
    IO.inspect apx_incoming_host
    case apx_incoming_host do
      false ->
        conn
      _ ->
        # sets the host for the request as the custom domain,
        # because the router will scope routes by matching hosts.
        %Plug.Conn{conn | host: apx_incoming_host}
    end
  end
end
