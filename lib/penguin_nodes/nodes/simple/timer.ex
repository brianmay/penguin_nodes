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
      description: "Generate a message once every timer period",
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

  @spec save_state(state :: NodeModule.State.t()) :: NodeModule.State.t()
  def save_state(%NodeModule.State{} = state) do
    save_state_map(state, %{"timer_set" => state.assigns.timer != nil})
  end

  @spec load_state(state :: NodeModule.State.t()) :: map()
  def load_state(%NodeModule.State{} = state) do
    timer_set =
      case load_state_map(state) do
        {:ok, data} ->
          Map.fetch!(data, "timer_set")

        {:error, _} ->
          state.opts.initial == :start
      end

    timer =
      if timer_set do
        {:ok, timer} = :timer.send_interval(state.opts.interval, :timer)
        timer
      else
        nil
      end

    %{timer: timer}
  end

  @impl true
  def init(%NodeModule.State{} = state, %Node{} = node) do
    %Options{} = node.opts
    assigns = load_state(state)
    state = %NodeModule.State{state | assigns: assigns}
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

        state =
          state
          |> assign(timer: timer)
          |> save_state()

        :ok = NodeModule.output(state, :value, state.opts.start_data)
        {:noreply, state}

      state.assigns.timer != nil and not data ->
        # timer set and cancel requested
        :timer.cancel(state.assigns.timer)

        state =
          state
          |> assign(timer: nil)
          |> save_state()

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
