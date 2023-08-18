defmodule Blogz.SimpleCache do
  @moduledoc """
  A simple ETS based cache for expensive function calls.
  Must be created in the application.ex like so:
  :ets.new(:simple_cache, [:set, :public, :named_table])
  """

  @doc """
  Retrieve a cached value or apply the given function caching and returning
  the result.
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
