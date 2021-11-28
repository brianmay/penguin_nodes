defmodule PenguinNodes.Mqtt.In do
  @moduledoc """
  A simple timer node
  """
  use PenguinNodes.Nodes.NodeModule

  alias PenguinNodes.Mqtt.Message
  alias PenguinNodes.MqttMultiplexer
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.NodeModule
  alias PenguinNodes.Nodes.Wire

  defmodule Options do
    @moduledoc """
    Options for the timer node
    """
    @type t :: %__MODULE__{
            topic: list(String.t()),
            format: :json | :raw,
            resend: :resend | :no_resend
          }
    @enforce_keys [:topic]
    defstruct @enforce_keys ++ [{:format, :raw}, {:resend, :resend}]
  end

  @impl true
  def init(%NodeModule.State{} = state, %Node{} = node) do
    %Options{} = options = node.opts
    state = %NodeModule.State{state | assigns: options}
    # Process.sleep(5_000)
    MqttMultiplexer.subscribe(options.topic, :mqtt, self(), options.format, options.resend)
    {:ok, state}
  end

  @impl true
  def handle_cast({:mqtt, topic, :mqtt, payload}, %NodeModule.State{} = state) do
    message = %Message{
      topic: topic,
      payload: payload
    }

    :ok = NodeModule.output(state, :mqtt, message)
    {:noreply, state}
  end

  @spec call(opts :: Options.t(), node_id :: Id.t()) :: Wire.t()
  def call(%Options{} = opts, node_id) do
    nodes = NodeModule.call(__MODULE__, %{}, opts, node_id)
    Wire.new(nodes, node_id, :mqtt)
  end
end
