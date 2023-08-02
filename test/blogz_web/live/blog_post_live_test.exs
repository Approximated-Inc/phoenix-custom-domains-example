defmodule BlogzWeb.BlogPostLiveTest do
  use BlogzWeb.ConnCase

  import Phoenix.LiveViewTest
  import Blogz.BlogPostsFixtures

  @create_attrs %{content: "some content", title: "some title"}
  @update_attrs %{content: "some updated content", title: "some updated title"}
  @invalid_attrs %{content: nil, title: nil}

  defp create_blog_post(_) do
    blog_post = blog_post_fixture()
    %{blog_post: blog_post}
  end

  describe "Index" do
    setup [:create_blog_post]

    test "lists all blog_posts", %{conn: conn, blog_post: blog_post} do
      {:ok, _index_live, html} = live(conn, ~p"/blog_posts")

      assert html =~ "Listing Blog posts"
      assert html =~ blog_post.content
    end

    test "saves new blog_post", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/blog_posts")

      assert index_live |> element("a", "New Blog post") |> render_click() =~
               "New Blog post"

      assert_patch(index_live, ~p"/blog_posts/new")

      assert index_live
             |> form("#blog_post-form", blog_post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#blog_post-form", blog_post: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/blog_posts")

      html = render(index_live)
      assert html =~ "Blog post created successfully"
      assert html =~ "some content"
    end

    test "updates blog_post in listing", %{conn: conn, blog_post: blog_post} do
      {:ok, index_live, _html} = live(conn, ~p"/blog_posts")

      assert index_live |> element("#blog_posts-#{blog_post.id} a", "Edit") |> render_click() =~
               "Edit Blog post"

      assert_patch(index_live, ~p"/blog_posts/#{blog_post}/edit")

      assert index_live
             |> form("#blog_post-form", blog_post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#blog_post-form", blog_post: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/blog_posts")

      html = render(index_live)
      assert html =~ "Blog post updated successfully"
      assert html =~ "some updated content"
    end

    test "deletes blog_post in listing", %{conn: conn, blog_post: blog_post} do
      {:ok, index_live, _html} = live(conn, ~p"/blog_posts")

      assert index_live |> element("#blog_posts-#{blog_post.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#blog_posts-#{blog_post.id}")
    end
  end

  describe "Show" do
    setup [:create_blog_post]

    test "displays blog_post", %{conn: conn, blog_post: blog_post} do
      {:ok, _show_live, html} = live(conn, ~p"/blog_posts/#{blog_post}")

      assert html =~ "Show Blog post"
      assert html =~ blog_post.content
    end

    test "updates blog_post within modal", %{conn: conn, blog_post: blog_post} do
      {:ok, show_live, _html} = live(conn, ~p"/blog_posts/#{blog_post}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Blog post"

      assert_patch(show_live, ~p"/blog_posts/#{blog_post}/show/edit")

      assert show_live
             |> form("#blog_post-form", blog_post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#blog_post-form", blog_post: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/blog_posts/#{blog_post}")

      html = render(show_live)
      assert html =~ "Blog post updated successfully"
      assert html =~ "some updated content"
    end
  end
end
