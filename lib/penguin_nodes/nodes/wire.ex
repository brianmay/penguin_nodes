defmodule PenguinNodes.Nodes.Wire do
  @moduledoc """
  A wire that comes out of an output and connects to other nodes
  """
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Nodes.Output
  alias PenguinNodes.Nodes.Types

  @type t :: %__MODULE__{
          nodes: Nodes.t(),
          output: Output.t()
        }
  @enforce_keys [:nodes, :output]
  defstruct @enforce_keys

  @spec new(Nodes.t(), node_id :: Id.t(), id :: atom(), type :: Types.data_type()) :: t()
  def new(%Nodes{} = nodes, node_id, id, type) do
    %__MODULE__{nodes: nodes, output: %Output{node_id: node_id, id: id, type: type}}
  end

  @spec get_outputs_from_list(list(t())) :: list(Output.t())
  def get_outputs_from_list(list) do
    Enum.reduce(list, [], fn wire, acc ->
      [wire.output | acc]
    end)
  end
end
