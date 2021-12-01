defmodule PenguinNodes.Nodes.Nodes do
  @moduledoc """
  A map of nodes
  """
  alias PenguinNodes.Nodes.Forward
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.NodeModule
  alias PenguinNodes.Nodes.Wire

  @type t :: %__MODULE__{
          map: %{Id.t() => Node.t()}
        }
  @enforce_keys [:map]
  defstruct @enforce_keys

  @spec new :: t()
  def new do
    %__MODULE__{map: %{}}
  end

  @spec build(t()) :: t()
  def build(%__MODULE__{} = nodes) do
    outputs_map =
      Enum.reduce(nodes.map, %{}, fn {_node_id, %Node{} = node}, outputs_map ->
        Node.reduce_inputs(node, outputs_map, fn key, output, outputs_map ->
          forward = %Forward{
            id: key,
            node_id: node.node_id,
            type: output.type
          }

          Map.update(outputs_map, {output.node_id, output.id}, [forward], fn value ->
            [forward | value]
          end)
        end)
      end)

    map =
      Enum.reduce(outputs_map, nodes.map, fn {{node_id, id}, outputs}, map ->
        %Node{} = node = Map.fetch!(map, node_id)
        node_outputs = Map.put(node.outputs, id, outputs)
        node = %Node{node | outputs: node_outputs}
        Map.put(map, node_id, node)
      end)

    %__MODULE__{nodes | map: map}
  end

  @spec child_spec(t()) :: list(Supervisor.child_spec())
  def child_spec(%__MODULE__{} = nodes) do
    Enum.map(nodes.map, fn {_node_id, %Node{} = node} ->
      Supervisor.child_spec({NodeModule, node}, id: node.node_id)
    end)
  end

  @spec merge(nodes :: t(), object :: t() | Wire.t() | list(t() | Wire.t())) :: t()
  def merge(%__MODULE__{} = nodes1, %__MODULE__{} = nodes2) do
    map = Map.merge(nodes1.map, nodes2.map)
    %__MODULE__{map: map}
  end

  def merge(%__MODULE__{} = nodes, %Wire{} = wire) do
    merge(nodes, wire.nodes)
  end

  def merge(%__MODULE__{} = nodes1, list) when is_list(list) do
    Enum.reduce(list, nodes1, fn nodes, acc -> merge(acc, nodes) end)
  end

  @spec add_node(nodes :: t(), node :: Node.t()) :: t()
  def add_node(%__MODULE__{} = nodes, %Node{} = node) do
    map = Map.put(nodes.map, node.node_id, node)
    %__MODULE__{map: map}
  end
end
