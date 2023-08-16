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
  This will run for *every* request and websocket connection though, so you
  may want to handle this differently in your own app. For instance, you may
  want to cache the allowed domains in ETS and check against that instead.
  This will depend on your application's designs and needs.
  """
  def origin_allowed?(%URI{host: host}) do
    Enum.member?(Application.get_env(:blogz, :primary_domains), host)
    or Repo.exists?(from b in Blog, where: b.custom_domain == ^host)
  end
end
