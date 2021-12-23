defmodule PenguinNodes.Repo.Migrations.CreateNodeStates do
  use Ecto.Migration

  def change do
    create table(:node_states) do
      add :node_id, :string
      add :state, :map

      timestamps()
    end

    create unique_index(:node_states, [:node_id])
  end
end
