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

  @spec save_state(state :: NodeModule.State.t()) :: NodeModule.State.t()
  def save_state(%NodeModule.State{} = state) do
    save_state_map(state, %{
      "timer_set" => state.assigns.timer != nil,
      "sent" => state.assigns.sent
    })
  end

  @spec load_state(state :: NodeModule.State.t()) :: map()
  def load_state(%NodeModule.State{} = state) do
    {timer_set, sent} =
      case load_state_map(state) do
        {:ok, data} ->
          {Map.fetch!(data, "timer_set"), Map.fetch!(data, "sent")}

        {:error, _} ->
          {false, nil}
      end

    timer =
      if timer_set do
        Process.send_after(self(), :timer, state.opts.interval)
      else
        nil
      end

    %{timer: timer, sent: sent}
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
    :ok = NodeModule.output(state, :value, true)

    state =
      state
      |> assign(timer: nil, sent: true)
      |> save_state()

    {:noreply, state}
  end

  @impl true
  @spec handle_input(:value, any, NodeModule.State.t()) ::
          {:noreply, NodeModule.State.t()}
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_input(:value, data, %NodeModule.State{} = state) do
    data = !!data
    sent = state.assigns.sent

    cond do
      state.assigns.timer == nil and data == true and sent != true ->
        # timer not set and we got true and we didn't send true
        timer = Process.send_after(self(), :timer, state.opts.interval)

        state =
          state
          |> assign(timer: timer)
          |> save_state()

        {:noreply, state}

      state.assigns.timer != nil and data == false ->
        # timer set and cancel requested
        # Note we can't get here is sent == true,
        # because the timer activation will disable the timer,
        # and then we can't reset timer until false received.
        Process.cancel_timer(state.assigns.timer)

        state =
          state
          |> assign(timer: nil)
          |> save_state()

        {:noreply, state}

      data == true ->
        # we already sent true and received true
        {:noreply, state}

      data == false and sent != false and sent != nil ->
        # timer not set and received false and didn't send false
        :ok = NodeModule.output(state, :value, false)

        state =
          state
          |> assign(sent: false)
          |> save_state()

        {:noreply, state}

      data == false ->
        # timer not set and received false but already sent false
        {:noreply, state}
    end
  end
end
