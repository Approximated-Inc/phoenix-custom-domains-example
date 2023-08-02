defmodule Blogz.Blogs.Blog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "blogs" do
    field :custom_domain, :string
    field :name, :string
    belongs_to :user, Blogz.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(blog, attrs) do
    blog
    |> cast(attrs, [:name, :custom_domain])
    |> validate_required([:name])
  end
end
