defmodule Blogz.Repo.Migrations.CreateBlogs do
  use Ecto.Migration

  def change do
    create table(:blogs) do
      add :name, :string
      add :custom_domain, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:blogs, [:user_id])
  end
end
