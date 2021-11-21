defmodule PenguinNodes.Repo do
  use Ecto.Repo,
    otp_app: :penguin_nodes,
    adapter: Ecto.Adapters.Postgres
end
