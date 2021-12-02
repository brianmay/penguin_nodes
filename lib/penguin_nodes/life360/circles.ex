defmodule PenguinNodes.Life360.Circles do
  @moduledoc """
  A simple timer node
  """
  use PenguinNodes.Nodes.NodeModule

  alias PenguinNodes.Nodes.Meta
  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.NodeModule

  import PenguinNodes.Life360.Helpers

  @impl true
  @spec get_meta :: PenguinNodes.Nodes.Meta.t()
  def get_meta do
    %Meta{
      description: "Receive Life360 circles",
      inputs: %{},
      outputs: %{
        value: %Meta.Output{description: "The Life360 person", type: :map}
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

  @impl true
  def init(%NodeModule.State{} = state, %Node{} = node) do
    %Options{} = options = node.opts
    state = %NodeModule.State{state | assigns: Map.from_struct(options)}

    Process.send_after(self(), :timer, 0)
    {:ok, state}
  end

  @spec do_circles(state :: NodeModule.State.t(), login :: map(), circles :: list(map())) :: :ok
  defp do_circles(_, _, []) do
    :ok
  end

  defp do_circles(state, login, [head | tail]) do
    case get_circle_info(login, head) do
      {:ok, circle} ->
        Enum.each(circle["members"], fn member ->
          output(state, :value, member)
        end)

        do_circles(state, login, tail)

      {:error, error} ->
        error(state, "life360 error", %{error: error})
        :ok
    end
  end

  @spec handle_timer(NodeModule.State.t()) :: NodeModule.State.t()
  def handle_timer(%NodeModule.State{} = state) do
    debug(state, "Got timer", %{})

    with {:ok, login} <- login(),
         {:ok, circles} <- list_circles(login) do
      :ok = do_circles(state, login, circles["circles"])
    else
      {:error, error} -> error(state, "life360 error", %{error: error})
    end

    Process.send_after(self(), :timer, 60_000)
    state
  end

  @impl true
  def handle_info(:timer, %NodeModule.State{} = state) do
    state = handle_timer(state)
    {:noreply, state}
  end
end
