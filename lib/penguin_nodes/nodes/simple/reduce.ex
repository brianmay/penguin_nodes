defmodule PenguinNodes.Nodes.Simple.Reduce do
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
      description: "Change the value using a function and a state",
      inputs: %{
        value: %Meta.Input{description: "The input value", type: :any}
      },
      outputs: %{
        value: %Meta.Output{description: "The mapped output value", type: :any}
      }
    }
  end

  @spec save_state(state :: NodeModule.State.t()) :: NodeModule.State.t()
  def save_state(%NodeModule.State{} = state) do
    save_state_map(state, state.assigns)
  end

  @spec load_state(state :: NodeModule.State.t()) :: map()
  def load_state(%NodeModule.State{} = state) do
    case load_state_map(state) do
      {:ok, data} ->
        data

      {:error, _} ->
        %{}
    end
  end

  defmodule Options do
    @moduledoc """
    Options for the timer node
    """
    @type reduce_func :: (any(), any() -> {any(), any()})
    @type t :: %__MODULE__{
            func: reduce_func(),
            acc: any()
          }
    @enforce_keys [:func]
    defstruct @enforce_keys ++ [{:acc, nil}]
  end

  @impl true
  def init(%NodeModule.State{} = state, %Node{} = node) do
    %Options{} = node.opts
    assigns = load_state(state)
    state = %NodeModule.State{state | assigns: assigns}
    {:ok, state}
  end

  @impl true
  @spec handle_input(:value, any, PenguinNodes.Nodes.NodeModule.State.t()) ::
          {:noreply, PenguinNodes.Nodes.NodeModule.State.t()}
  def handle_input(:value, data, %NodeModule.State{} = state) do
    {data, assigns} = state.opts.func.(data, state.assigns)

    state =
      %NodeModule.State{state | assigns: assigns}
      |> save_state()

    :ok = output(state, :value, data)
    {:noreply, state}
  end
end
