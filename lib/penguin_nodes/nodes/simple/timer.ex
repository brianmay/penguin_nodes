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
      inputs: %{
        value: %Meta.Input{description: "True to start timer, false to cancel", type: :boolean}
      },
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
            initial: :start | :stop,
            start_data: any(),
            data: any(),
            end_data: any(),
            interval: integer()
          }
    @enforce_keys [:interval, :initial]
    defstruct @enforce_keys ++ [start_data: :start, data: :timer, end_data: :end]
  end

  @impl true
  def init(%NodeModule.State{} = state, %Node{} = node) do
    %Options{} = node.opts

    timer =
      case node.opts.initial do
        :start -> :timer.send_interval(state.opts.interval, :timer)
        :stop -> nil
      end

    state = assign(state, timer: timer)
    {:ok, state}
  end

  @impl true
  def restart(%NodeModule.State{} = state, %Node{}) do
    state =
      if state.assigns.timer do
        timer = :timer.send_interval(state.opts.interval, :timer)
        assign(state, timer: timer)
      else
        state
      end

    {:ok, state}
  end

  @impl true
  def handle_info(:timer, %NodeModule.State{} = state) do
    :ok = NodeModule.output(state, :value, state.opts.data)
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
        {:ok, timer} = :timer.send_interval(state.opts.interval, :timer)
        state = assign(state, timer: timer)
        :ok = NodeModule.output(state, :value, state.opts.start_data)
        {:noreply, state}

      state.assigns.timer != nil and not data ->
        # timer set and cancel requested
        :timer.cancel(state.assigns.timer)
        state = assign(state, timer: nil)
        :ok = NodeModule.output(state, :value, state.opts.end_data)
        {:noreply, state}

      data ->
        # timer set and received true
        {:noreply, state}

      not data ->
        # timer not set and received false
        {:noreply, state}
    end
  end
end
