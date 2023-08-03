defmodule Blogz.Approximated do
  @moduledoc """
  A module for interacting with the Approximated.app API.

  Why do we need this?
  Well, there's 3 parts to handling custom domains for an app:

  1. DNS/Routing - Getting a request from user device to your app through a custom domain
  2. TLS/SSL - Securing the request for the custom domain
  3. App - Handling the custom domain request in the app itself

  Approximated nicely handles the first 2 for us so that we can focus on number 3.

  Note: we aren't checking for success on any of the requests
  so that you can run this example without an Approximated account.
  In that case, you'll need to route and possibly SSl secure the
  custom domains in some other way, in order to test a real custom domain.
  """

  @primary_domain Application.compile_env(:blogz, :primary_domains, ["localhost"])
                  |> List.first("localhost")

  def create_vhost(incoming_address) do
    json = %{
      incoming_address: incoming_address,
      target_address: @primary_domain,
      target_ports: "443"
    }

    Req.post("https://cloud.approximated.app/api/vhosts",
      json: json,
      headers: [api_key: Application.get_env(:blogz, :apx_api_key)]
    )
  end

  def update_vhost(current_incoming_address, new_incoming_address) do
    json = %{
      current_incoming_address: current_incoming_address,
      incoming_address: new_incoming_address,
      target_address: @primary_domain,
      target_ports: "443"
    }

    Req.post("https://cloud.approximated.app/api/vhosts/update/by/incoming",
      json: json,
      headers: [api_key: Application.get_env(:blogz, :apx_api_key)]
    )
  end

  def delete_vhost(incoming_address) do
    Req.delete("https://cloud.approximated.app/api/vhosts/by/incoming/#{incoming_address}",
      headers: [api_key: Application.get_env(:blogz, :apx_api_key)]
    )
  end
end
