defmodule PenguinNodes.Nodes.Output do
  @moduledoc """
  A specific output on a node
  """
  alias PenguinNodes.Nodes.Id

  @type t :: %__MODULE__{
          node_id: Id.t(),
          id: atom()
        }
  @enforce_keys [:node_id, :id]
  defstruct @enforce_keys
end
