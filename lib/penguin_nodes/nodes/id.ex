defmodule PenguinNodes.Nodes.Id do
  @moduledoc """
  Generate guaranteed unique id values
  """
  use GenServer

  @type t :: tuple()

  @doc """
  Create a new id from a base and a given atom
  """
  @spec id(root_id :: t(), id :: atom()) :: t()
  def id(root_id, id) do
    Tuple.append(root_id, id)
  end

  @spec start_link(keyword()) :: {:ok, pid} | {:error, any()}
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Ensure this id is not already used on this Elixir Node
  """
  @spec allocate_id(pid :: GenServer.server(), id :: t()) :: :ok | :error
  def allocate_id(pid \\ __MODULE__, id) do
    GenServer.call(pid, {:allocate_id, id})
  end

  # Server (callbacks)

  @impl true
  def init(_opt) do
    {:ok, MapSet.new()}
  end

  @impl true
  def handle_call({:allocate_id, id}, _from, state) do
    case MapSet.member?(state, id) do
      true -> {:reply, :error, state}
      false -> {:reply, :ok, MapSet.put(state, id)}
    end
  end
end
