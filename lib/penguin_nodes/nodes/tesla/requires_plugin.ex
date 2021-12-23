defmodule PenguinNodes.Nodes.Tesla.RequiresPlugin do
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
      description: "Determine if Tesla requires plugin",
      inputs: %{
        battery_level: %Meta.Input{description: "What is the battery level?", type: :integer},
        plugged_in: %Meta.Input{description: "Is Tesla plugged in?", type: :boolean},
        geofence: %Meta.Input{description: "Where is the Tesla?", type: :string},
        reminder: %Meta.Input{description: "Are reminders enabled?", type: :boolean}
      },
      outputs: %{
        value: %Meta.Output{description: "True if tesla is insecure", type: :boolean}
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

  @spec save_state(state :: NodeModule.State.t()) :: NodeModule.State.t()
  def save_state(%NodeModule.State{} = state) do
    save_state_map(state, state.assigns)
  end

  @spec load_state(state :: NodeModule.State.t()) :: map()
  def load_state(%NodeModule.State{} = state) do
    case load_state_map(state) do
      {:ok, data} ->
        %{
          battery_level: Map.fetch!(data, "battery_level"),
          plugged_in: Map.fetch!(data, "plugged_in"),
          geofence: Map.fetch!(data, "geofence"),
          reminder: Map.fetch!(data, "reminder")
        }

      {:error, _} ->
        %{
          battery_level: nil,
          plugged_in: nil,
          geofence: nil,
          reminder: nil
        }
    end
  end

  @impl true
  def init(%NodeModule.State{} = state, %Node{} = node) do
    %Options{} = node.opts
    assigns = load_state(state)
    state = %NodeModule.State{state | assigns: assigns}
    {:ok, state}
  end

  @spec evaluate(state :: NodeModule.State.t()) :: NodeModule.State.t()
  defp evaluate(%NodeModule.State{} = state) do
    battery_level = state.assigns.battery_level
    plugged_in = state.assigns.plugged_in
    geofence = state.assigns.geofence
    reminder = state.assigns.reminder

    case {battery_level, plugged_in, geofence, reminder} do
      {nil, _, _, _} -> :ok
      {_, nil, _, _} -> :ok
      {_, _, "", _} -> :ok
      {_, _, _, nil} -> :ok
      {level, false, "Home", true} when level < 75 -> :ok = NodeModule.output(state, :value, true)
      {_, _, _, _} -> :ok = NodeModule.output(state, :value, false)
    end

    state
  end

  @impl true
  @spec handle_input(:battery_level, any(), NodeModule.State.t()) ::
          {:noreply, NodeModule.State.t()}
  def handle_input(:battery_level, data, %NodeModule.State{} = state) do
    state =
      state
      |> assign(:battery_level, data)
      |> evaluate()
      |> save_state()

    {:noreply, state}
  end

  @impl true
  @spec handle_input(:plugged_in, any(), NodeModule.State.t()) ::
          {:noreply, NodeModule.State.t()}
  def handle_input(:plugged_in, data, %NodeModule.State{} = state) do
    state =
      state
      |> assign(:plugged_in, data)
      |> evaluate()
      |> save_state()

    {:noreply, state}
  end

  @impl true
  @spec handle_input(:geofence, any(), NodeModule.State.t()) ::
          {:noreply, NodeModule.State.t()}
  def handle_input(:geofence, data, %NodeModule.State{} = state) do
    state =
      state
      |> assign(:geofence, data)
      |> evaluate()
      |> save_state()

    {:noreply, state}
  end

  @impl true
  @spec handle_input(:reminder, any(), NodeModule.State.t()) ::
          {:noreply, NodeModule.State.t()}
  def handle_input(:reminder, data, %NodeModule.State{} = state) do
    state =
      state
      |> assign(:reminder, data)
      |> evaluate()
      |> save_state()

    {:noreply, state}
  end
end
