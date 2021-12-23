defmodule PenguinNodes.Nodes.Tesla.Insecure do
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
      description: "Determine if Tesla is insecure",
      inputs: %{
        is_user_present: %Meta.Input{description: "Is user present?", type: :boolean},
        locked: %Meta.Input{description: "Is tesla locked?", type: :boolean}
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
          is_user_present: Map.fetch!(data, "is_user_present"),
          locked: Map.fetch!(data, "locked")
        }

      {:error, _} ->
        %{
          is_user_present: nil,
          locked: nil
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
    is_user_present = state.assigns.is_user_present
    locked = state.assigns.locked

    case {is_user_present, locked} do
      {nil, _} -> :ok
      {_, nil} -> :ok
      {false, false} -> :ok = NodeModule.output(state, :value, true)
      {_, _} -> :ok = NodeModule.output(state, :value, false)
    end

    state
  end

  @impl true
  @spec handle_input(:is_user_present, any(), NodeModule.State.t()) ::
          {:noreply, NodeModule.State.t()}
  def handle_input(:is_user_present, data, %NodeModule.State{} = state) do
    state =
      state
      |> assign(:is_user_present, data)
      |> evaluate()
      |> save_state()

    {:noreply, state}
  end

  @impl true
  @spec handle_input(:locked, any(), NodeModule.State.t()) ::
          {:noreply, NodeModule.State.t()}
  def handle_input(:locked, data, %NodeModule.State{} = state) do
    state =
      state
      |> assign(:locked, data)
      |> evaluate()
      |> save_state()

    {:noreply, state}
  end
end
