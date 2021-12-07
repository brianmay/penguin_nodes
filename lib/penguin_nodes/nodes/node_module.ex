defmodule PenguinNodes.Nodes.NodeModule do
  @moduledoc """
  Wrapper genserver for nodes
  """
  use GenServer
  require Logger

  alias PenguinNodes.Nodes.Forward
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Meta
  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Nodes.Output
  alias PenguinNodes.Nodes.Types
  alias PenguinNodes.Nodes.Wire

  defmodule State do
    @moduledoc """
    State for nodes
    """
    @type t :: %__MODULE__{
            node_id: Id.t(),
            module: module(),
            inputs: %{atom() => list(Output.t())},
            outputs: %{atom() => list(Forward.t())},
            assigns: map(),
            opts: struct()
          }
    @enforce_keys [:node_id, :module, :inputs, :outputs, :assigns, :opts]
    defstruct @enforce_keys
  end

  defmodule LogMessage do
    @moduledoc """
    State for nodes
    """
    @type t :: %__MODULE__{
            level: atom(),
            datetime: DateTime.t(),
            module: module(),
            node_id: Id.t(),
            hostname: String.t(),
            message: String.t(),
            values: map(),
            state: map()
          }
    @enforce_keys [:level, :datetime, :module, :node_id, :hostname, :message, :values, :state]
    defstruct @enforce_keys
  end

  defmacro __using__(_opts) do
    quote do
      use GenServer
      @behaviour PenguinNodes.Nodes.NodeModule
      import PenguinNodes.Nodes.NodeModule
      alias PenguinNodes.Nodes.NodeModule

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

  @callback restart(state :: State.t(), node :: Node.t()) ::
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

  @callback get_meta :: Meta.t()
  @optional_callbacks restart: 2, handle_input: 3

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

  @spec do_output2(data :: any(), list(Forward.t())) :: :ok
  defp do_output2(data, outputs) do
    Enum.each(outputs, fn
      %Forward{} = forward ->
        case wait_for_pid(forward.node_id) do
          :ok -> GenServer.cast({:global, forward.node_id}, {:input, forward.id, data})
          :error -> Logger.error("Cannot send message to node.")
        end
    end)

    :ok
  end

  @spec output(state :: State.t(), id :: atom(), data :: any()) :: :ok
  def output(%State{} = state, id, data) do
    case Map.fetch(state.outputs, id) do
      {:ok, outputs} ->
        debug(state, "Sending data to output", %{output: id, data: data})
        :ok = do_output2(data, outputs)

      :error ->
        debug(state, "Output not found", %{output: id, data: data})
        :ok
    end
  end

  @doc """
  Convenience function to assign a list of values into a state struct.
  """
  @spec assign(state :: State.t(), key_list :: Keyword.t()) :: State.t()
  def assign(%State{} = state, key_list) when is_list(key_list) do
    Enum.reduce(key_list, state, fn {k, v}, acc -> assign(acc, k, v) end)
  end

  @doc """
  Convenience function to assign a value into a state struct.
  """
  @spec assign(state :: State.t(), key :: any, value :: any) :: State.t()
  def assign(%State{assigns: assigns} = state, key, value) do
    %{state | assigns: Map.put(assigns, key, value)}
  end

  @doc """
  Convenience function to assign a list of new values into a state struct.
  Only values that do not already exist will be assigned
  """
  @spec assign_new(state :: State.t(), key_list :: Keyword.t()) :: State.t()
  def assign_new(%State{} = state, key_list) when is_list(key_list) do
    Enum.reduce(key_list, state, fn {k, v}, acc -> assign_new(acc, k, v) end)
  end

  @doc """
  Convenience function to assign a new values into a state struct.
  The value will only be assigned if it does not already exist in the struct.
  """
  @spec assign_new(state :: State.t(), key :: any, value :: any) :: State.t()
  def assign_new(%State{assigns: assigns} = state, key, value) do
    %{state | assigns: Map.put_new(assigns, key, value)}
  end

  @spec start_link(Node.t()) :: {:ok, pid} | {:error, any()}
  def start_link(%Node{} = node) do
    GenServer.start_link(__MODULE__, node)
  end

  @spec check_type(got_type :: Types.data_type(), expected_type :: Types.data_type()) ::
          :ok | :error
  defp check_type(got_type, expected_type) do
    case {got_type, expected_type} do
      {x, x} -> :ok
      {:any, _} -> :ok
      {_, :any} -> :ok
      _ -> :error
    end
  end

  @spec check_type!(got_type :: Types.data_type(), expected_type :: Types.data_type()) :: :ok
  defp check_type!(got_type, expected_type) do
    case check_type(got_type, expected_type) do
      :ok -> :ok
      :error -> raise("Got type #{got_type} but expected type #{expected_type}")
    end
  end

  @spec call(module :: module(), inputs :: input_map(), opts :: map(), id :: Id.t()) ::
          {%{atom() => Wire.t()}, Nodes.t()}
  def call(module, inputs, opts, node_id) do
    %Meta{} = meta = module.get_meta()

    case Id.allocate_id(node_id) do
      :ok -> nil
      :error -> raise("Cannot allocate id #{inspect(node_id)}")
    end

    inputs =
      Enum.map(inputs, fn {key, input_value} ->
        case input_value do
          value when is_list(value) -> {key, value}
          %Wire{} = wire -> {key, [wire]}
        end
      end)

    Enum.each(inputs, fn {key, input_list} ->
      Enum.each(input_list, fn %Wire{} = wire ->
        got_type = wire.output.type
        %Meta.Input{} = meta_input = Map.fetch!(meta.inputs, key)
        expected_type = meta_input.type
        :ok = check_type!(got_type, expected_type)
      end)
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

    nodes =
      inputs
      |> Enum.reduce(Nodes.new(), fn {_, wires}, nodes -> Nodes.merge(nodes, wires) end)
      |> Nodes.add_node(node)

    wires =
      Enum.reduce(meta.outputs, %{}, fn {key, %Meta.Output{} = output}, wires ->
        wire = Wire.new(nodes, node_id, key, output.type)
        Map.put(wires, key, wire)
      end)

    {wires, nodes}
  end

  @spec log(atom(), State.t(), String.t(), map()) :: :ok
  def log(:debug, %State{}, _message, _values), do: :ok

  def log(level, %State{} = state, message, values) do
    {:ok, hostname} = :inet.gethostname()
    hostname = to_string(hostname)

    data = %{
      level: level,
      datetime: DateTime.utc_now(),
      module: state.module,
      node_id: state.node_id,
      hostname: hostname,
      message: message,
      values: values,
      state: state
    }

    string_level = Atom.to_string(level)
    Logger.log(level, "Node #{inspect(state.node_id)}: #{string_level}: #{inspect(data)}")
    PenguinNodesWeb.Endpoint.broadcast!("logs", string_level, data)
  end

  @spec debug(State.t(), String.t(), map()) :: :ok
  def debug(%State{} = state, message, values) do
    log(:debug, state, message, values)
  end

  @spec info(State.t(), String.t(), map()) :: :ok
  def info(%State{} = state, message, values) do
    log(:info, state, message, values)
  end

  @spec notice(State.t(), String.t(), map()) :: :ok
  def notice(%State{} = state, message, values) do
    log(:notice, state, message, values)
  end

  @spec warning(State.t(), String.t(), map()) :: :ok
  def warning(%State{} = state, message, values) do
    log(:warning, state, message, values)
  end

  @spec error(State.t(), String.t(), map()) :: :ok
  def error(%State{} = state, message, values) do
    log(:error, state, message, values)
  end

  # # Server (callbacks)

  @impl true
  def init(%Node{} = node) do
    {:ok, nil, {:continue, {:_init, node}}}
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_continue({:_init, %Node{} = node}, nil) do
    module = node.module

    assigns = DeltaCrdt.get(PenguinNodes.Crdt, node.node_id)

    {init, assigns} =
      cond do
        assigns == nil ->
          {&node.module.init/2, %{}}

        function_exported?(node.module, :restart, 2) ->
          init = &node.module.restart/2
          {init, assigns}

        true ->
          init = fn %State{} = state, %Node{} -> {:ok, state} end
          {init, assigns}
      end

    state = %State{
      node_id: node.node_id,
      module: module,
      inputs: node.inputs,
      outputs: node.outputs,
      assigns: assigns,
      opts: node.opts
    }

    # start up the state
    rc = init.(state, node)
    :ok = save_state_from_rc(rc)

    case rc do
      {:ok, %State{} = state} ->
        {:noreply, state}

      {:ok, _other} ->
        raise "Invalid response from #{inspect(init)} State must be a %State{}"

      {:ok, %State{} = state, opt} ->
        {:noreply, state, opt}

      {:ok, _other, _opt} ->
        raise "Invalid response from #{inspect(init)} State must be a %State{}"

      :ignore ->
        :ignore

      {:stop, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(msg, %State{module: module} = state) do
    rc = module.handle_continue(msg, state)
    :ok = save_state_from_rc(rc)

    case rc do
      {:noreply, %State{} = state} -> {:noreply, state}
      {:noreply, %State{} = state, opts} -> {:noreply, state, opts}
      response -> response
    end
  end

  @impl true
  def handle_info(msg, %State{module: module} = state) do
    rc = module.handle_info(msg, state)
    :ok = save_state_from_rc(rc)

    case rc do
      {:noreply, %State{} = state} -> {:noreply, state}
      {:noreply, %State{} = state, opts} -> {:noreply, state, opts}
      response -> response
    end
  end

  @impl true
  def handle_call(:get_state, _, %State{} = state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(msg, from, %State{module: module} = state) do
    rc = module.handle_call(msg, from, state)
    :ok = save_state_from_rc(rc)

    case rc do
      {:noreply, %State{} = state} -> {:noreply, state}
      {:noreply, %State{} = state, opts} -> {:noreply, state, opts}
      {:reply, reply, %State{} = state} -> {:reply, reply, state}
      {:reply, reply, %State{} = state, opts} -> {:reply, reply, state, opts}
      response -> response
    end
  end

  @impl true
  def handle_cast({:input, id, data}, %State{module: module} = state) do
    debug(state, "Received data from input", %{input: id, data: data})
    rc = module.handle_input(id, data, state)
    :ok = save_state_from_rc(rc)
    rc
  end

  @impl true
  def handle_cast(msg, %State{module: module} = state) do
    rc = module.handle_cast(msg, state)
    :ok = save_state_from_rc(rc)

    case rc do
      {:noreply, %State{} = state} -> {:noreply, state}
      {:noreply, %State{} = state, opts} -> {:noreply, state, opts}
      response -> response
    end
  end

  @impl true
  def terminate(reason, %State{} = state) do
    error(state, "Node terminating", %{reason: reason})
  end

  @spec save_state_from_rc(rc :: any()) :: :ok
  def save_state_from_rc({:noreply, %State{} = state}), do: save_state(state)
  def save_state_from_rc({:noreply, %State{} = state, _}), do: save_state(state)
  def save_state_from_rc({:reply, _, %State{} = state}), do: save_state(state)
  def save_state_from_rc({:reply, _, %State{} = state, _}), do: save_state(state)
  def save_state_from_rc({:ok, _, %State{} = state}), do: save_state(state)
  def save_state_from_rc({:ok, _, %State{} = state, _}), do: save_state(state)
  def save_state_from_rc(_), do: :ok

  @spec save_state(State.t()) :: :ok
  def save_state(%State{} = state) do
    DeltaCrdt.put(PenguinNodes.Crdt, state.node_id, state.assigns)
    :ok
  end
end
