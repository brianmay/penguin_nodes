defmodule PenguinNodes.Nodes.Life360.Circles do
  @moduledoc """
  A simple timer node
  """
  use PenguinNodes.Nodes.NodeModule

  alias PenguinNodes.Nodes.Meta
  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.NodeModule

  import PenguinNodes.Nodes.Life360.Helpers

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
    %Options{} = node.opts
    Process.send_after(self(), :timer, 0)
    {:ok, state}
  end

  @spec do_circles(state :: NodeModule.State.t(), login :: map(), circles :: list(map())) ::
          {:error, String.t() | Finch.Error.t()} | :ok
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
        {:error, error}
    end
  end

  @spec handle_timer(NodeModule.State.t()) :: NodeModule.State.t()
  def handle_timer(%NodeModule.State{} = state) do
    debug(state, "Got timer", %{})

    with {:ok, login} <- login(),
         {:ok, circles} <- list_circles(login),
         :ok <- do_circles(state, login, circles["circles"]) do
      nil
    else
      {:error, error} -> error(state, "life360 error", %{error: error})
    end

    Process.send_after(self(), :timer, 15_000)
    state
  end

  @impl true
  def handle_info(:timer, %NodeModule.State{} = state) do
    state = handle_timer(state)
    {:noreply, state}
  end
end
