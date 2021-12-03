defmodule PenguinNodes.Nodes.Simple.Switch do
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
      description: "Switch a value based on a boolean input",
      inputs: %{
        value: %Meta.Input{description: "The input value", type: :any},
        switch: %Meta.Input{description: "The boolean value", type: :boolean}
      },
      outputs: %{
        value: %Meta.Output{
          description: "The same value if the switch value was true",
          type: :any
        },
        inverted: %Meta.Output{
          description: "The same value if the switch value was not true",
          type: :any
        }
      }
    }
  end

  defmodule Options do
    @moduledoc """
    Options for the timer node
    """
    @type filter_func :: (any() -> boolean())
    @type t :: %__MODULE__{}
    @enforce_keys []
    defstruct @enforce_keys
  end

  @impl true
  def init(%NodeModule.State{} = state, %Node{} = node) do
    %Options{} = node.opts
    state = assign(state, :switch, nil)
    {:ok, state}
  end

  @impl true
  @spec handle_input(:value, any, PenguinNodes.Nodes.NodeModule.State.t()) ::
          {:noreply, PenguinNodes.Nodes.NodeModule.State.t()}
  def handle_input(:value, data, %NodeModule.State{} = state) do
    case state.assigns.switch do
      true -> :ok = NodeModule.output(state, :value, data)
      false -> :ok = NodeModule.output(state, :inverted, data)
      nil -> :ok
    end

    {:noreply, state}
  end

  @impl true
  @spec handle_input(:switch, boolean(), PenguinNodes.Nodes.NodeModule.State.t()) ::
          {:noreply, PenguinNodes.Nodes.NodeModule.State.t()}
  def handle_input(:switch, data, %NodeModule.State{} = state) do
    state = assign(state, :switch, !!data)
    {:noreply, state}
  end
end
