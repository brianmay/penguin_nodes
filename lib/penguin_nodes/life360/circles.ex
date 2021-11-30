defmodule PenguinNodes.Life360.Circles do
  @moduledoc """
  A simple timer node
  """
  use PenguinNodes.Nodes.NodeModule

  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.NodeModule
  alias PenguinNodes.Nodes.Wire

  import PenguinNodes.Life360.Helpers

  defmodule Inputs do
    @moduledoc """
    Inputs for the Debug Node
    """
    @type t :: %__MODULE__{}
    @enforce_keys []
    defstruct @enforce_keys
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
        error(state, "life360 error #{inspect(error)}", %{})
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
      {:error, error} -> error(state, "life360 error #{inspect(error)}", %{})
    end

    Process.send_after(self(), :timer, 60_000)
    state
  end

  @impl true
  def handle_info(:timer, %NodeModule.State{} = state) do
    state = handle_timer(state)
    {:noreply, state}
  end

  @spec call(inputs :: Inputs.t(), opts :: Options.t(), node_id :: Id.t()) :: Wire.t()
  def call(%Inputs{} = inputs, %Options{} = opts, node_id) do
    inputs = Map.from_struct(inputs)
    nodes = NodeModule.call(__MODULE__, inputs, opts, node_id)
    Wire.new(nodes, node_id, :value)
  end
end
