defmodule Blogz.BlogPosts do
  @moduledoc """
  The BlogPosts context.
  """

  import Ecto.Query, warn: false
  alias Blogz.Repo

  alias Blogz.BlogPosts.BlogPost

  @doc """
  Returns the list of blog_posts.

  ## Examples

      iex> list_blog_posts()
      [%BlogPost{}, ...]

  """
  def list_blog_posts do
    Repo.all(BlogPost)
  end

  def list_blog_posts(blog_id) when is_integer(blog_id) do
    Repo.all(from bp in BlogPost, where: bp.blog_id == ^blog_id)
  end

  @doc """
  Gets a single blog_post.

  Raises `Ecto.NoResultsError` if the Blog post does not exist.

  ## Examples

      iex> get_blog_post!(123)
      %BlogPost{}

      iex> get_blog_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_blog_post!(id), do: Repo.get!(BlogPost, id)

  def get_post_by_blog_and_slug(blog_id, slug) do
    Repo.one!(from bp in BlogPost, where: bp.blog_id == ^blog_id and bp.slug == ^slug)
  end

  @doc """
  Creates a blog_post.

  ## Examples

      iex> create_blog_post(%{field: value})
      {:ok, %BlogPost{}}

      iex> create_blog_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_blog_post(blog_id, user_id, attrs \\ %{}) do
    blog = Blogz.Blogs.get_blog!(blog_id)
    user = Blogz.Accounts.get_user!(user_id)

    %BlogPost{}
    |> BlogPost.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:blog, blog)
    |> Repo.insert()
  end

  @doc """
  Updates a blog_post.

  ## Examples

      iex> update_blog_post(blog_post, %{field: new_value})
      {:ok, %BlogPost{}}

      iex> update_blog_post(blog_post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_blog_post(%BlogPost{} = blog_post, attrs) do
    blog_post
    |> BlogPost.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a blog_post.

  ## Examples

      iex> delete_blog_post(blog_post)
      {:ok, %BlogPost{}}

      iex> delete_blog_post(blog_post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_blog_post(%BlogPost{} = blog_post) do
    Repo.delete(blog_post)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking blog_post changes.

  ## Examples

      iex> change_blog_post(blog_post)
      %Ecto.Changeset{data: %BlogPost{}}

  """
  def change_blog_post(%BlogPost{} = blog_post, attrs \\ %{}) do
    BlogPost.changeset(blog_post, attrs)
  end
end
