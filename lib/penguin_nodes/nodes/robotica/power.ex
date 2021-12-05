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
        scenes: %Meta.Input{description: "Robotica Scenes", type: :list},
        power: %Meta.Input{description: "Robotica Power", type: :string}
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
    state = assign(state, scenes: nil, power: nil)
    {:ok, state}
  end

  @spec evaluate(state :: NodeModule.State.t()) :: :ok
  defp evaluate(%NodeModule.State{} = state) do
    scenes = state.assigns.scenes
    power = state.assigns.power

    case {scenes, power} do
      {nil, _} ->
        :ok

      {_, nil} ->
        :ok

      {[], power} ->
        :ok = NodeModule.output(state, :value, power)

      {scenes, _} ->
        power =
          if Enum.member?(scenes, "default") do
            "ON"
          else
            "OFF"
          end

        :ok = NodeModule.output(state, :value, power)
    end
  end

  @impl true
  @spec handle_input(:scenes, any(), NodeModule.State.t()) ::
          {:noreply, NodeModule.State.t()}
  def handle_input(:scenes, data, %NodeModule.State{} = state) do
    state = assign(state, :scenes, data)
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
