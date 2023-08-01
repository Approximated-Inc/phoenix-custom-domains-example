defmodule BlogzWeb.CustomDomainsPlug do
  @behaviour Plug
  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    {_, apx_incoming_host} = Enum.find(conn.req_headers, false, fn {header, value} -> header == "apx-incoming-host" end)
    cond do
      # Does this have a header telling us the custom domain?
      apx_incoming_host != false ->
        # yes, continue

    end
  end
end
