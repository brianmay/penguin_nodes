defmodule PenguinNodes.Mqtt.In do
  @moduledoc """
  A simple timer node
  """
  use PenguinNodes.Nodes.NodeModule

  alias PenguinNodes.Mqtt.Message
  alias PenguinNodes.MqttMultiplexer
  alias PenguinNodes.Nodes.Meta
  alias PenguinNodes.Nodes.Node

  @impl true
  def get_meta do
    %Meta{
      description: "Receive a mqtt message",
      inputs: %{},
      outputs: %{
        value: %Meta.Output{description: "The incoming MQTT message", type: Message}
      }
    }
  end

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
    MqttMultiplexer.subscribe(options.topic, :mqtt, self(), options.format, options.resend)
    {:ok, state}
  end

  @impl true
  def handle_cast({:mqtt, topic, :mqtt, payload}, %NodeModule.State{} = state) do
    message = %Message{
      topic: topic,
      payload: payload
    }

    :ok = NodeModule.output(state, :value, message)
    {:noreply, state}
  end
end
