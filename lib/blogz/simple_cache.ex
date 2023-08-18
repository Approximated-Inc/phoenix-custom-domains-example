defmodule Blogz.SimpleCache do
  @moduledoc """
  A simple ETS based cache for expensive function calls.
  Must be created in the application.ex like so:
  :ets.new(:simple_cache, [:set, :public, :named_table])
  """

  @doc """
  Run a function, cache it's value in ETS, then return the value
  if the exact combination of arguments haven't been run before (or it's past the TTL).

  If it has been run before, and we're within the TTL (default 1 hour),
  return the previously cached result immediately instead.

  ## Parameters
    - mod: A module like Blogz.Blogs
    - fun: The atomic name for the function you want to call, like :get_blog_by_custom_domain
    - args: A list of args that you want to feed the function in the order it's expecting, like ["acustomdomain.com"]
    - opts: (optional) A keyword list of options for the caching function itself, like [ttl: 300]

  ## Examples
    iex> Blogz.SimpleCache.get(Blogz.Blogs, :get_blog_by_custom_domain, ["existingcustomdomain.com"], [ttl: 300])
    %Blogz.Blogs.Blog{}

    iex> Blogz.SimpleCache.get(Blogz.Blogs, :get_blog_by_custom_domain, ["notinourdatabse.com"], [ttl: 300])
    nil
  """
  def get(mod, fun, args, opts \\ []) do
    case lookup(mod, fun, args) do
      nil ->
        ttl = Keyword.get(opts, :ttl, 3600)
        cache_apply(mod, fun, args, ttl)

      result ->
        result
    end
  end

  # Lookup a cached result and check the freshness
  defp lookup(mod, fun, args) do
    case :ets.lookup(:simple_cache, [mod, fun, args]) do
      [result | _] -> check_freshness(result)
      [] -> nil
    end
  end

  # Compare the result expiration against the current system time.
  defp check_freshness({_mfa, result, expiration}) do
    cond do
      expiration > :os.system_time(:seconds) -> result
      :else -> nil
    end
  end

  # Apply the function, calculate expiration, and cache the result.
  defp cache_apply(mod, fun, args, ttl) do
    result = apply(mod, fun, args)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(:simple_cache, {[mod, fun, args], result, expiration})
    result
  end
end
