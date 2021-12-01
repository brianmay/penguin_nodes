defmodule PenguinNodes.Simple.Changed do
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
      description: "Check if input has changed since the last message",
      inputs: %{
        value: %Meta.Input{description: "The value to check", type: :any}
      },
      outputs: %{
        value: %Meta.Output{description: "The value to check", type: Message}
      }
    }
  end

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
    %Options{} = node.opts
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
end
