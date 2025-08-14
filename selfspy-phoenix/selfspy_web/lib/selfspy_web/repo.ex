defmodule SelfspyWeb.Repo do
  use Ecto.Repo,
    otp_app: :selfspy_web,
    adapter: Ecto.Adapters.Postgres
end
