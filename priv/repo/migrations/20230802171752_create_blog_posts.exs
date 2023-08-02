defmodule Blogz.Repo.Migrations.CreateBlogPosts do
  use Ecto.Migration

  def change do
    create table(:blog_posts) do
      add :title, :string
      add :content, :text
      add :slug, :string
      add :user_id, references(:users, on_delete: :delete_all)
      add :blog_id, references(:blogs, on_delete: :delete_all)

      timestamps()
    end

    create index(:blog_posts, [:user_id])
    create index(:blog_posts, [:blog_id])
  end
end
