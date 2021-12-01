defmodule PenguinNodes.Nodes.Output do
  @moduledoc """
  A specific output on a node
  """
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Types

  @type t :: %__MODULE__{
          node_id: Id.t(),
          type: Types.data_type(),
          id: atom()
        }
  @enforce_keys [:node_id, :type, :id]
  defstruct @enforce_keys
end
