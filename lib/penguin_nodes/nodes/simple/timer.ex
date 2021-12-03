defmodule PenguinNodes.Nodes.Simple.Timer do
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
      description: "Generate a message once eveyr timer period",
      inputs: %{},
      outputs: %{
        value: %Meta.Output{description: "The output value", type: :any}
      }
    }
  end

  defmodule Options do
    @moduledoc """
    Options for the timer node
    """
    @type t :: %__MODULE__{
            data: any(),
            interval: integer()
          }
    @enforce_keys [:data, :interval]
    defstruct @enforce_keys
  end

  @impl true
  def init(%NodeModule.State{} = state, %Node{} = node) do
    %Options{} = options = node.opts
    :timer.send_interval(options.interval, :timer)
    {:ok, state}
  end

  @impl true
  def handle_info(:timer, %NodeModule.State{} = state) do
    :ok = NodeModule.output(state, :timer, state.opts.data)
    {:noreply, state}
  end
end
