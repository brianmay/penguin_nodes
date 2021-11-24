defmodule PenguinNodes.Simple.Debug do
  use PenguinNodes.Nodes.NodeModule

  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Nodes.NodeModule

  require Logger

  defmodule Options do
    @moduledoc """
    Options for the Debug node
    """
    @type t :: %__MODULE__{}
    @enforce_keys []
    defstruct @enforce_keys
  end

  @impl true
  def init(%NodeModule.State{} = state, %Node{} = node) do
    %Options{} = options = node.opts
    state = %NodeModule.State{state | assigns: options}
    {:ok, state}
  end

  @impl true
  def handle_input(:value, data, state) do
    Logger.debug("DEBUG: #{inspect(data)}")
    {:noreply, state}
  end

  @spec call(value :: NodeModule.input_value(), opts :: Options.t()) :: Nodes.t()
  def call(value, %Options{} = opts) do
    {_node_id, nodes} = NodeModule.call(__MODULE__, %{value: value}, opts)
    nodes
  end
end
