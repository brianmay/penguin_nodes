defmodule PenguinNodes.Nodes.Mqtt.Out do
  use PenguinNodes.Nodes.NodeModule

  alias PenguinNodes.Nodes.Meta
  alias PenguinNodes.Nodes.Mqtt.Message
  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.NodeModule

  require Logger

  @impl true
  def get_meta do
    %Meta{
      description: "Send a mqtt message",
      inputs: %{
        value: %Meta.Input{description: "The outgoing MQTT message", type: :Message}
      },
      outputs: %{}
    }
  end

  defmodule Options do
    @moduledoc """
    Options for the Debug node
    """
    @type t :: %__MODULE__{
            topic: list(String.t()) | nil,
            format: :raw | :json,
            retain: boolean(),
            qos: integer()
          }
    @enforce_keys []
    defstruct @enforce_keys ++ [{:format, :raw}, {:topic, nil}, {:retain, false}, {:qos, 0}]
  end

  @impl true
  def init(%NodeModule.State{} = state, %Node{} = node) do
    %Options{} = node.opts
    {:ok, state}
  end

  @impl true
  def handle_input(:value, %Message{} = message, %NodeModule.State{} = state) do
    topic =
      if state.opts.topic == nil do
        message.topic
      else
        state.opts.topic
      end

    raw_payload =
      case state.opts.format do
        :raw ->
          message.payload

        :json ->
          payload =
            if is_struct(message.payload) do
              message.payload |> Map.from_struct()
            else
              message.payload
            end

          case Jason.encode(payload) do
            {:error, reason} ->
              error(state, "Cannot encode payload: #{inspect(reason)}", %{data: payload})

            {:ok, value} ->
              value
          end
      end

    opts = [
      retain: state.opts.retain,
      qos: state.opts.qos
    ]

    if topic == nil do
      error(state, "Message topic not supplied for outgoing message", %{})
    else
      topic = Enum.join(topic, "/")
      MqttPotion.publish(PenguinNodes.Mqtt, topic, raw_payload, opts)
    end

    {:noreply, state}
  end
end
