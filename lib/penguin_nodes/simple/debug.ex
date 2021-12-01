defmodule PenguinNodes.Simple.Debug do
  use PenguinNodes.Nodes.NodeModule

  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.NodeModule
  alias PenguinNodes.Nodes.Nodes

  require Logger

  defmodule Inputs do
    @moduledoc """
    Inputs for the Debug Node
    """
    @type t :: %__MODULE__{
            value: NodeModule.input_value()
          }
    @enforce_keys [:value]
    defstruct @enforce_keys
  end

  defmodule Options do
    @moduledoc """
    Options for the Debug node
    """
    @type t :: %__MODULE__{
            message: String.t(),
            level: atom()
          }
    @enforce_keys []
    defstruct @enforce_keys ++ [{:level, :info}, {:message, "Got debug data"}]
  end

  @impl true
  def init(%NodeModule.State{} = state, %Node{} = node) do
    %Options{} = node.opts
    {:ok, state}
  end

  @impl true
  def handle_input(:value, data, %NodeModule.State{} = state) do
    log(state.opts.level, state, state.opts.message, %{data: data})
    :ok = NodeModule.output(state, :value, data)
    {:noreply, state}
  end

  @spec call(inputs :: Inputs.t(), opts :: Options.t(), node_id :: Id.t()) :: Nodes.t()
  def call(%Inputs{} = inputs, %Options{} = opts, node_id) do
    inputs = Map.from_struct(inputs)
    NodeModule.call(__MODULE__, inputs, opts, node_id)
  end
end
