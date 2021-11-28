defmodule PenguinNodes.Simple.Changed do
  @moduledoc """
  A simple timer node
  """
  use PenguinNodes.Nodes.NodeModule

  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.NodeModule
  alias PenguinNodes.Nodes.Wire

  defmodule Options do
    @moduledoc """
    Options for the timer node
    """
    @type t :: %__MODULE__{}
    @enforce_keys []
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
    %Options{} = options = node.opts
    state = %NodeModule.State{state | assigns: options}
    {:ok, state}
  end

  @impl true
  @spec handle_input(:value, any, PenguinNodes.Nodes.NodeModule.State.t()) ::
          {:noreply, PenguinNodes.Nodes.NodeModule.State.t()}
  def handle_input(:value, data, %NodeModule.State{} = state) do
    # Attempt to fetch previous value
    case Map.fetch(state.assigns, :data) do
      {:ok, old_data} ->
        # Previous value was stored.
        if old_data == data do
          {:noreply, state}
        else
          changed = %Message{
            old: old_data,
            new: data
          }

          :ok = NodeModule.output(state, :value, changed)
          state = assign(state, :data, data)
          {:noreply, state}
        end

      :error ->
        # No previous value stored.
        state = assign(state, :data, data)
        {:noreply, state}
    end
  end

  @spec call(value :: NodeModule.input_value(), opts :: Options.t(), node_id :: Id.t()) ::
          Wire.t()
  def call(value, %Options{} = opts, node_id) do
    nodes = NodeModule.call(__MODULE__, %{value: value}, opts, node_id)
    Wire.new(nodes, node_id, :value)
  end
end
