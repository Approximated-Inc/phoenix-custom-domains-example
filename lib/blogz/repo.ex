defmodule Blogz.Repo do
  use Ecto.Repo,
    otp_app: :blogz,
    adapter: Ecto.Adapters.Postgres
end
