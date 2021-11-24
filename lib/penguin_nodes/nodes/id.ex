defmodule PenguinNodes.Nodes.Id do
  @moduledoc """
  Generate guaranteed unique id values
  """
  use GenServer

  @type t :: atom()

  # Client

  @spec start_link(keyword()) :: {:ok, pid} | {:error, any()}
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec get_next_id(pid :: GenServer.server()) :: t()
  def get_next_id(pid \\ __MODULE__) do
    id = GenServer.call(pid, :get_next_id)
    String.to_atom("node_#{id}")
  end

  # Server (callbacks)

  @impl true
  def init(_opt) do
    {:ok, 0}
  end

  @impl true
  def handle_call(:get_next_id, _from, id) do
    {:reply, id, id + 1}
  end
end
