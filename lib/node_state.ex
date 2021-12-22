defmodule PenguinNodes.NodeState do
  @moduledoc """
  Save node state
  """
  use Mnesiac.Store
  import Record, only: [defrecord: 3]

  alias PenguinNodes.Nodes.Id

  defrecord(
    :node_state,
    :node_state,
    node_id: nil,
    state: nil
  )

  @type node_state ::
          record(
            :node_state,
            node_id: Id.t(),
            state: any()
          )

  @impl true
  def store_options,
    do: [
      record_name: :node_state,
      attributes: node_state() |> node_state() |> Keyword.keys(),
      index: [:node_id],
      ram_copies: [node()]
    ]

  @spec put(Id.t(), any()) :: :ok
  def put(node_id, state) do
    :mnesia.transaction(fn ->
      {:node_state, node_id: node_id, state: state}
      |> :mnesia.write()
    end)

    :ok
  end

  @spec get(Id.t()) :: {:ok, any()} | {:error, atom()}
  def get(node_id) do
    :mnesia.transaction(fn ->
      :mnesia.read({:node_state, node_id})
    end)
    |> case do
      {:atomic, [{:node_state, _, state}]} -> {:ok, state}
      _ -> {:error, :not_found}
    end
  end
end
