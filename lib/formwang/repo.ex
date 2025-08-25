defmodule Formwang.Repo do
  use Ecto.Repo,
    otp_app: :formwang,
    adapter: Ecto.Adapters.Postgres
end
