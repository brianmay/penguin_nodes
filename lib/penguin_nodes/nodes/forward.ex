defmodule PenguinNodes.Nodes.Forward do
  @moduledoc """
  How to forward data to a node
  """
  alias PenguinNodes.Nodes.Id

  @type t :: %__MODULE__{
          id: atom(),
          node_id: Id.t()
        }
  @enforce_keys [:id, :node_id]
  defstruct @enforce_keys
end
