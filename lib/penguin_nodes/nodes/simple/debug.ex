defmodule PenguinNodes.Nodes.Simple.Debug do
  use PenguinNodes.Nodes.NodeModule

  alias PenguinNodes.Nodes.Meta
  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.NodeModule

  require Logger

  @impl true
  def get_meta do
    %Meta{
      description: "Log the value for debugging",
      inputs: %{
        value: %Meta.Input{description: "The value to check", type: :any}
      },
      outputs: %{
        value: %Meta.Output{description: "The same value", type: :any}
      }
    }
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
end
