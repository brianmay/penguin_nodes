defmodule PenguinNodes.Config do
  @moduledoc """
  Generate guaranteed unique id values
  """
  use GenServer

  alias PenguinNodes.Flows
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.NodeModule
  alias PenguinNodes.Nodes.Nodes

  @spec start_link(keyword()) :: {:ok, pid} | {:error, any()}
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Ensure this id is not already used on this Elixir Node
  """
  @spec get_node(pid :: GenServer.server(), id :: Id.t()) :: {:ok, Node.t()} | :error
  def get_node(pid \\ __MODULE__, id) do
    GenServer.call(pid, {:get_node, id})
  end

  @spec get_nodes(pid :: GenServer.server()) :: Nodes.t()
  def get_nodes(pid \\ __MODULE__) do
    GenServer.call(pid, :get_nodes)
  end

  # Server (callbacks)
  @spec nodes :: Nodes.t()
  defp nodes do
    Flows.generate_flow({}) |> Nodes.build()
  end

  @impl true
  def init(_opt) do
    nodes = nodes()

    Enum.each(nodes.map, fn {_, %Node{} = node} ->
      IO.puts("Starting #{inspect(node.node_id)}")
      {:ok, _pid} = Singleton.start_child(NodeModule, node, node.node_id)
    end)

    {:ok, nodes}
  end

  @impl true
  def handle_call({:get_node, id}, _from, %Nodes{} = state) do
    node = Map.fetch(state.map, id)
    {:reply, node, state}
  end

  @impl true
  def handle_call(:get_nodes, _from, %Nodes{} = state) do
    {:reply, state, state}
  end
end
