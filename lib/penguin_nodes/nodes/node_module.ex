defmodule PenguinNodes.Nodes.NodeModule do
  @moduledoc """
  Wrapper genserver for nodes
  """
  use GenServer
  require Logger

  alias PenguinNodes.Nodes.Forward
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Nodes.Wire

  defmodule State do
    @moduledoc """
    State for nodes
    """
    @type t :: %__MODULE__{
            node_id: Id.t(),
            module: module(),
            outputs: %{atom() => list(Forward.t())},
            assigns: map()
          }
    @enforce_keys [:node_id, :module, :outputs, :assigns]
    defstruct @enforce_keys
  end

  defmacro __using__(_opts) do
    quote do
      use GenServer
      @behaviour PenguinNodes.Nodes.NodeModule

      @doc false
      def init(_param), do: :ignore
    end
  end

  @type response_opts ::
          list(
            timeout()
            | :hibernate
            | {:continue, term}
          )

  @type input_value :: Wire.t() | list(Wire.t())
  @type input_map :: %{atom() => input_value()}

  @callback init(state :: State.t(), node :: Node.t()) ::
              {:ok, state}
              | {:ok, state, timeout :: non_neg_integer}
              | {:ok, state, :hibernate}
              | {:ok, state, opts :: response_opts()}
              | :ignore
              | {:stop, reason}
            when state: State.t(), reason: term()

  @callback handle_input(id :: atom(), data :: Node.data(), state :: State.t()) ::
              {:noreply, State.t()}
              | {:noreply, State.t(), timeout}
              | {:noreply, State.t(), :hibernate}
              | {:noreply, State.t(), opts :: response_opts()}

  @optional_callbacks handle_input: 3

  @spec wait_for_pid(node_id :: Id.t(), tries :: integer()) :: :ok | :error
  defp wait_for_pid(node_id, tries \\ 3)

  defp wait_for_pid(_node_id, 0) do
    :error
  end

  defp wait_for_pid(node_id, tries) do
    case :global.whereis_name(node_id) do
      :undefined ->
        IO.puts("sleeping #{tries}")
        Process.sleep(1000)
        wait_for_pid(node_id, tries - 1)

      _pid ->
        :ok
    end
  end

  @spec output(state :: State.t(), id :: atom(), data :: map()) :: :ok
  def output(%State{} = state, id, data) do
    outputs = Map.fetch!(state.outputs, id)

    Enum.each(outputs, fn
      %Forward{} = forward ->
        case wait_for_pid(forward.node_id) do
          :ok -> GenServer.cast({:global, forward.node_id}, {:input, forward.id, data})
          :error -> Logger.error("Cannot send message to node.")
        end
    end)

    :ok
  end

  @spec start_link(Node.t()) :: {:ok, pid} | {:error, any()}
  def start_link(%Node{} = node) do
    GenServer.start_link(__MODULE__, node)
  end

  @spec call(module :: module(), inputs :: input_map(), opts :: map(), id :: Id.t()) :: Nodes.t()
  def call(module, inputs, opts, node_id) do
    inputs =
      Enum.map(inputs, fn {key, input_value} ->
        case input_value do
          value when is_list(value) -> {key, value}
          %Wire{} = wire -> {key, [wire]}
        end
      end)

    input_map =
      inputs
      |> Enum.map(fn {key, wires} -> {key, Wire.get_outputs_from_list(wires)} end)
      |> Enum.into(%{})

    node = %Node{
      node_id: node_id,
      module: module,
      inputs: input_map,
      outputs: %{},
      opts: opts
    }

    inputs
    |> Enum.reduce(Nodes.new(), fn {_, wires}, nodes -> Nodes.merge(nodes, wires) end)
    |> Nodes.add_node(node)
  end

  # # Server (callbacks)

  @impl true
  def init(%Node{} = node) do
    {:ok, nil, {:continue, {:_init, node}}}
  end

  def handle_continue({:_init, node}, nil) do
    module = node.module

    state = %State{
      node_id: node.node_id,
      module: module,
      outputs: node.outputs,
      assigns: %{}
    }

    # start up the state
    case node.module.init(state, node) do
      {:ok, %State{} = state} ->
        {:noreply, state}

      {:ok, _other} ->
        raise "Invalid response from #{module}.init/3 State must be a %State{}"

      {:ok, %State{} = state, opt} ->
        {:noreply, state, opt}

      {:ok, _other, _opt} ->
        raise "Invalid response from #{module}.init/3 State must be a %State{}"

      :ignore ->
        :ignore

      {:stop, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(msg, %State{module: module} = state) do
    case module.handle_continue(msg, state) do
      {:noreply, %State{} = state} -> {:noreply, state}
      {:noreply, %State{} = state, opts} -> {:noreply, state, opts}
      response -> response
    end
  end

  @impl true
  def handle_info(msg, %State{module: module} = state) do
    case module.handle_info(msg, state) do
      {:noreply, %State{} = state} -> {:noreply, state}
      {:noreply, %State{} = state, opts} -> {:noreply, state, opts}
      response -> response
    end
  end

  @impl true
  def handle_call(msg, from, %State{module: module} = state) do
    case module.handle_call(msg, from, state) do
      {:noreply, %State{} = state} -> {:noreply, state}
      {:noreply, %State{} = state, opts} -> {:noreply, state, opts}
      {:reply, reply, %State{} = state} -> {:reply, reply, state}
      {:reply, reply, %State{} = state, opts} -> {:reply, reply, state, opts}
      response -> response
    end
  end

  @impl true
  def handle_cast({:input, id, data}, %State{module: module} = state) do
    module.handle_input(id, data, state)
  end

  @impl true
  def handle_cast(msg, %State{module: module} = state) do
    case module.handle_cast(msg, state) do
      {:noreply, %State{} = state} -> {:noreply, state}
      {:noreply, %State{} = state, opts} -> {:noreply, state, opts}
      response -> response
    end
  end
end
