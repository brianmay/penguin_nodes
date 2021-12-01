defmodule PenguinNodes.Nodes.Forward do
  @moduledoc """
  How to forward data to a node
  """
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Types

  @type t :: %__MODULE__{
          id: atom(),
          type: Types.data_type(),
          node_id: Id.t()
        }
  @enforce_keys [:id, :type, :node_id]
  defstruct @enforce_keys
end
