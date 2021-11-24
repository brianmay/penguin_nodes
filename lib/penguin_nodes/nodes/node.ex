defmodule PenguinNodes.Nodes.Node do
  @moduledoc """
  Represents an instance of a node with complete settings
  """
  alias PenguinNodes.Nodes.Forward
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Output

  @type t :: %__MODULE__{
          node_id: Id.t(),
          module: module(),
          inputs: %{atom() => list(Output.t())},
          outputs: %{atom() => list(Forward.t())},
          opts: struct()
        }
  @enforce_keys [:node_id, :module, :inputs, :outputs, :opts]
  defstruct @enforce_keys

  @type data :: map()
end
