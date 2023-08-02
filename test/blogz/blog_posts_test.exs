defmodule Blogz.BlogPostsTest do
  use Blogz.DataCase

  alias Blogz.BlogPosts

  describe "blog_posts" do
    alias Blogz.BlogPosts.BlogPost

    import Blogz.BlogPostsFixtures

    @invalid_attrs %{content: nil, title: nil}

    test "list_blog_posts/0 returns all blog_posts" do
      blog_post = blog_post_fixture()
      assert BlogPosts.list_blog_posts() == [blog_post]
    end

    test "get_blog_post!/1 returns the blog_post with given id" do
      blog_post = blog_post_fixture()
      assert BlogPosts.get_blog_post!(blog_post.id) == blog_post
    end

    test "create_blog_post/1 with valid data creates a blog_post" do
      valid_attrs = %{content: "some content", title: "some title"}

      assert {:ok, %BlogPost{} = blog_post} = BlogPosts.create_blog_post(valid_attrs)
      assert blog_post.content == "some content"
      assert blog_post.title == "some title"
    end

    test "create_blog_post/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = BlogPosts.create_blog_post(@invalid_attrs)
    end

    test "update_blog_post/2 with valid data updates the blog_post" do
      blog_post = blog_post_fixture()
      update_attrs = %{content: "some updated content", title: "some updated title"}

      assert {:ok, %BlogPost{} = blog_post} = BlogPosts.update_blog_post(blog_post, update_attrs)
      assert blog_post.content == "some updated content"
      assert blog_post.title == "some updated title"
    end

    test "update_blog_post/2 with invalid data returns error changeset" do
      blog_post = blog_post_fixture()
      assert {:error, %Ecto.Changeset{}} = BlogPosts.update_blog_post(blog_post, @invalid_attrs)
      assert blog_post == BlogPosts.get_blog_post!(blog_post.id)
    end

    test "delete_blog_post/1 deletes the blog_post" do
      blog_post = blog_post_fixture()
      assert {:ok, %BlogPost{}} = BlogPosts.delete_blog_post(blog_post)
      assert_raise Ecto.NoResultsError, fn -> BlogPosts.get_blog_post!(blog_post.id) end
    end

    test "change_blog_post/1 returns a blog_post changeset" do
      blog_post = blog_post_fixture()
      assert %Ecto.Changeset{} = BlogPosts.change_blog_post(blog_post)
    end
  end
end
