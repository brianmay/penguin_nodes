defmodule PenguinNodes.Nodes.Simple.Delay do
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
      description: "Send true value after delay and cancel with false value",
      inputs: %{
        value: %Meta.Input{description: "The input value", type: :boolean}
      },
      outputs: %{
        value: %Meta.Output{description: "The output value", type: :boolean}
      }
    }
  end

  defmodule Options do
    @moduledoc """
    Options for the timer node
    """
    @type t :: %__MODULE__{
            interval: integer()
          }
    @enforce_keys [:interval]
    defstruct @enforce_keys
  end

  @impl true
  def init(%NodeModule.State{} = state, %Node{} = node) do
    %Options{} = node.opts
    state = assign(state, timer: nil)
    {:ok, state}
  end

  @impl true
  def handle_info(:timer, %NodeModule.State{} = state) do
    :ok = NodeModule.output(state, :value, true)
    state = assign(state, timer: nil)
    {:noreply, state}
  end

  @impl true
  @spec handle_input(:value, any, NodeModule.State.t()) ::
          {:noreply, NodeModule.State.t()}
  def handle_input(:value, data, %NodeModule.State{} = state) do
    data = !!data

    cond do
      state.assigns.timer == nil and data ->
        # timer not set but requested
        timer = Process.send_after(self(), :timer, state.opts.interval)
        state = assign(state, timer: timer)
        {:noreply, state}

      state.assigns.timer != nil and not data ->
        # timer set and cancel requested
        Process.cancel_timer(state.assigns.timer)
        state = assign(state, timer: nil)
        :ok = NodeModule.output(state, :value, false)
        {:noreply, state}

      data ->
        # timer set and received true
        {:noreply, state}

      not data ->
        # timer not set and received false
        :ok = NodeModule.output(state, :value, false)
        {:noreply, state}
    end
  end
end
