defmodule PenguinNodes.Simple.Timer do
  @moduledoc """
  A simple timer node
  """
  use PenguinNodes.Nodes.NodeModule

  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.NodeModule
  alias PenguinNodes.Nodes.Wire

  defmodule Options do
    @moduledoc """
    Options for the timer node
    """
    @type t :: %__MODULE__{
            data: any()
          }
    @enforce_keys [:data]
    defstruct @enforce_keys
  end

  @impl true
  def init(%NodeModule.State{} = state, %Node{} = node) do
    %Options{} = options = node.opts
    state = %NodeModule.State{state | assigns: options}
    :timer.send_interval(1000, :timer)
    {:ok, state}
  end

  @impl true
  def handle_info(:timer, %NodeModule.State{} = state) do
    :ok = NodeModule.output(state, :timer, state.assigns.data)
    {:noreply, state}
  end

  @spec call(opts :: Options.t()) :: Wire.t()
  def call(%Options{} = opts) do
    {node_id, nodes} = NodeModule.call(__MODULE__, %{}, opts)
    Wire.new(nodes, node_id, :timer)
  end
end
