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

  @type reduce_inputs_fn :: (key :: atom(), output :: Output.t(), acc :: any() -> any())
  @spec reduce_inputs(node :: t(), acc :: any(), function :: reduce_inputs_fn()) :: any()
  def reduce_inputs(%__MODULE__{} = node, acc, function) do
    Enum.reduce(node.inputs, acc, fn {key, outputs}, acc ->
      Enum.reduce(outputs, acc, fn %Output{} = output, acc ->
        function.(key, output, acc)
      end)
    end)
  end
end
