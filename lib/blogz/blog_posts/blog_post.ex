defmodule Blogz.BlogPosts.BlogPost do
  use Ecto.Schema
  import Ecto.Changeset

  schema "blog_posts" do
    field :content, :string
    field :title, :string
    field :slug, :string
    belongs_to :user, Blogz.Accounts.User
    belongs_to :blog, Blogz.Blogs.Blog

    timestamps()
  end

  @doc false
  def changeset(blog_post, attrs) do
    blog_post
    |> cast(attrs, [:title, :content])
    |> Slugy.slugify(:title)
    |> validate_required([:title, :content, :slug])
  end
end
