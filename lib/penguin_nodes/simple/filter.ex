defmodule PenguinNodes.Simple.Filter do
  @moduledoc """
  A simple timer node
  """
  use PenguinNodes.Nodes.NodeModule

  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.NodeModule
  alias PenguinNodes.Nodes.Wire

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
    Options for the timer node
    """
    @type filter_func :: (any() -> boolean())
    @type t :: %__MODULE__{
            func: filter_func()
          }
    @enforce_keys [:func]
    defstruct @enforce_keys
  end

  defmodule Message do
    @moduledoc """
    NQTT Message
    """
    @type t :: %__MODULE__{
            new: any(),
            old: any()
          }
    @enforce_keys [:new, :old]
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
    case state.opts.func.(data) do
      true -> :ok = NodeModule.output(state, :value, data)
      false -> nil
    end

    {:noreply, state}
  end

  @spec call(inputs :: Inputs.t(), opts :: Options.t(), node_id :: Id.t()) :: Wire.t()
  def call(%Inputs{} = inputs, %Options{} = opts, node_id) do
    inputs = Map.from_struct(inputs)
    nodes = NodeModule.call(__MODULE__, inputs, opts, node_id)
    Wire.new(nodes, node_id, :value)
  end
end
