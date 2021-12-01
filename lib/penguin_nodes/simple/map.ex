defmodule PenguinNodes.Simple.Map do
  @moduledoc """
  A simple timer node
  """
  use PenguinNodes.Nodes.NodeModule

  alias PenguinNodes.Nodes.Meta
  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.NodeModule

  @impl true
  def get_meta do
    %Meta{
      description: "Change the value using a function",
      inputs: %{
        value: %Meta.Input{description: "The input value", type: :any}
      },
      outputs: %{
        value: %Meta.Output{description: "The mapped output value", type: :any}
      }
    }
  end

  defmodule Options do
    @moduledoc """
    Options for the timer node
    """
    @type map_func :: (any() -> any())
    @type t :: %__MODULE__{
            func: map_func()
          }
    @enforce_keys [:func]
    defstruct @enforce_keys
  end

  @impl true
  def init(%NodeModule.State{} = state, %Node{} = node) do
    %Options{} = node.opts
    {:ok, state}
  end

  @impl true
  @spec handle_input(:value, any, PenguinNodes.Nodes.NodeModule.State.t()) ::
          {:noreply, PenguinNodes.Nodes.NodeModule.State.t()}
  def handle_input(:value, data, %NodeModule.State{} = state) do
    data = state.opts.func.(data)
    :ok = NodeModule.output(state, :value, data)
    {:noreply, state}
  end
end
