defmodule PenguinNodes.Simple.Debug do
  use PenguinNodes.Nodes.NodeModule

  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.NodeModule
  alias PenguinNodes.Nodes.Nodes

  require Logger

  defmodule Options do
    @moduledoc """
    Options for the Debug node
    """
    @type t :: %__MODULE__{
            message: String.t(),
            level: atom()
          }
    @enforce_keys []
    defstruct @enforce_keys ++ [{:level, :debug}, {:message, "Got debug data"}]
  end

  @impl true
  def init(%NodeModule.State{} = state, %Node{} = node) do
    %Options{} = options = node.opts
    state = %NodeModule.State{state | assigns: options}
    {:ok, state}
  end

  @impl true
  def handle_input(:value, data, %NodeModule.State{} = state) do
    log(state.assigns.level, state, state.assigns.message, %{data: data})
    :ok = NodeModule.output(state, :value, data)
    {:noreply, state}
  end

  @spec call(value :: NodeModule.input_value(), opts :: Options.t(), node_id :: Id.t()) ::
          Nodes.t()
  def call(value, %Options{} = opts, node_id) do
    NodeModule.call(__MODULE__, %{value: value}, opts, node_id)
  end
end
