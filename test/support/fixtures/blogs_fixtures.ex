defmodule Blogz.BlogsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Blogz.Blogs` context.
  """

  @doc """
  Generate a blog.
  """
  def blog_fixture(attrs \\ %{}) do
    {:ok, blog} =
      attrs
      |> Enum.into(%{
        custom_domain: "some custom_domain",
        name: "some name"
      })
      |> Blogz.Blogs.create_blog()

    blog
  end
end
