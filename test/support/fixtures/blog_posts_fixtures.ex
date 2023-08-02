defmodule Blogz.BlogPostsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Blogz.BlogPosts` context.
  """

  @doc """
  Generate a blog_post.
  """
  def blog_post_fixture(attrs \\ %{}) do
    {:ok, blog_post} =
      attrs
      |> Enum.into(%{
        content: "some content",
        title: "some title"
      })
      |> Blogz.BlogPosts.create_blog_post()

    blog_post
  end
end
