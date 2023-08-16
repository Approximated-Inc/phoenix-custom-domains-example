defmodule BlogzWeb.OriginChecks do
  @moduledoc """
  This module contains functions for validating a domain origin for a request
  or a websocket against our list of primary domains and any existing blog custom domains.
  """
  import Ecto.Query, warn: false
  alias Blogz.Repo
  alias Blogz.Blogs.Blog

  @doc """
  This takes in a URI, such as the check_origin MFA option provides,
  and checks against our list of primary domains and custom domains.

  Returns a boolean.

  Performance Note:
  For simplicity, we're doing a database lookup if it's not in the primary domains list.
  If called directly, this will run for *every* request and websocket connection though.
  For that reason, we use a function that caches the result of this instead for 10 mins.
  """
  def origin_allowed?(%URI{host: host}) do
    origin_allowed?(host)
  end

  # A second func definition with just the host as arg,
  # so we can have a smaller cache memory footprint
  def origin_allowed?(host) when is_binary(host) do
    Enum.member?(Application.get_env(:blogz, :primary_domains), host)
    or Repo.exists?(from b in Blog, where: b.custom_domain == ^host)
  end

  @doc """
  This takes in a URI, such as the check_origin MFA option provides,
  and checks against our list of primary domains and custom domains.
  Returns a boolean.

  Note: this uses an ETS function cache with a 10 minute TTL.
  Your app will use slightly more memory this way, and it will grow
  depending on how many custom domains you have and how often they're requested.
  But with a 10 minute TTL, and a pretty small memory footprint (just the MFA and true/false) per cached check,
  you'd probably need a *lot* of domains being frequently hit for it to matter too much.
  """

  def cache_origin_allowed?(%URI{} = uri) do
    Blogz.SimpleCache.get(__MODULE__, :origin_allowed?, [uri.host], [ttl: 600])
  end
end
