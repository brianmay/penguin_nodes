defmodule PenguinNodes.Nodes.Robotica.Power do
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
      description: "Determine if light is on",
      inputs: %{
        priorities: %Meta.Input{description: "Robotica priorities", type: :list},
        power: %Meta.Input{description: "Robotica power", type: :string}
      },
      outputs: %{
        value: %Meta.Output{description: "Light power", type: :string}
      }
    }
  end

  defmodule Options do
    @moduledoc """
    Options for the timer node
    """
    @type map_func :: (any() -> any())
    @type t :: %__MODULE__{}
    @enforce_keys []
    defstruct @enforce_keys
  end

  @impl true
  def init(%NodeModule.State{} = state, %Node{} = node) do
    %Options{} = node.opts
    state = assign(state, priorities: nil, power: nil)
    {:ok, state}
  end

  @spec evaluate(state :: NodeModule.State.t()) :: :ok
  defp evaluate(%NodeModule.State{} = state) do
    priorities = state.assigns.priorities
    power = state.assigns.power

    case {priorities, power} do
      {_, nil} ->
        :ok

      {_, "HARD_OFF"} ->
        :ok = NodeModule.output(state, :value, power)

      {nil, _} ->
        :ok

      {[], power} ->
        :ok = NodeModule.output(state, :value, power)

      {priorities, _} ->
        power =
          if Enum.member?(priorities, 100) do
            "ON"
          else
            "OFF"
          end

        :ok = NodeModule.output(state, :value, power)
    end
  end

  @impl true
  @spec handle_input(:priorities, any(), NodeModule.State.t()) ::
          {:noreply, NodeModule.State.t()}
  def handle_input(:priorities, data, %NodeModule.State{} = state) do
    state = assign(state, :priorities, data)
    evaluate(state)
    {:noreply, state}
  end

  @impl true
  @spec handle_input(:power, any(), NodeModule.State.t()) ::
          {:noreply, NodeModule.State.t()}
  def handle_input(:power, data, %NodeModule.State{} = state) do
    state = assign(state, :power, data)
    evaluate(state)
    {:noreply, state}
  end
end
