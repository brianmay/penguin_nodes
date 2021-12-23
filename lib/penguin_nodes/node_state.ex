defmodule PenguinNodes.NodeState do
  @moduledoc """
  Save/restore node state
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Repo

  @timestamps_opts [type: :utc_datetime, usec: true]

  schema "node_states" do
    field :node_id, :string
    field :state, :map

    timestamps()
  end

  @doc false
  def changeset(node_state, attrs) do
    node_state
    |> cast(attrs, [:node_id, :state])
    |> validate_required([:node_id, :state])
  end

  @spec id_to_string(id :: Id.t()) :: String.t()
  defp id_to_string(id) do
    id
    |> Tuple.to_list()
    |> Enum.map_join("/", fn x -> Atom.to_string(x) end)
  end

  @spec put(Id.t(), any()) :: :ok
  def put(node_id, state) do
    id = id_to_string(node_id)

    ns = %__MODULE__{
      node_id: id,
      state: state
    }

    Repo.insert!(
      ns,
      on_conflict: [set: [state: state]],
      conflict_target: :node_id
    )

    :ok
  end

  @spec get(Id.t()) :: {:ok, any()} | {:error, atom()}
  def get(node_id) do
    id = id_to_string(node_id)

    case Repo.get_by(__MODULE__, node_id: id) do
      %__MODULE__{state: state} ->
        {:ok, state}

      nil ->
        {:error, :not_found}
    end
  end
end
