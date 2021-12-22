defmodule PenguinNodes.NodeState do
  @moduledoc """
  Save node state
  """
  alias PenguinNodes.Nodes.Id

  use Memento.Table, attributes: [:node_id, :state]

  @spec put(Id.t(), any()) :: :ok
  def put(node_id, state) do
    Memento.transaction!(fn ->
      %__MODULE__{node_id: node_id, state: state}
      |> Memento.Query.write()
    end)

    :ok
  end

  @spec get(Id.t()) :: {:ok, any()} | {:error, atom()}
  def get(node_id) do
    Memento.transaction!(fn ->
      Memento.Query.read(__MODULE__, node_id)
    end)
    |> case do
      %__MODULE__{state: state} -> {:ok, state}
      _ -> {:error, :not_found}
    end
  end
end
