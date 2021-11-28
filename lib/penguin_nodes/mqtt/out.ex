defmodule PenguinNodes.Mqtt.Out do
  use PenguinNodes.Nodes.NodeModule

  alias PenguinNodes.Mqtt.Message
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.NodeModule
  alias PenguinNodes.Nodes.Nodes

  require Logger

  defmodule Options do
    @moduledoc """
    Options for the Debug node
    """
    @type t :: %__MODULE__{
            topic: list(String.t()) | nil,
            format: :raw | :json
          }
    @enforce_keys []
    defstruct @enforce_keys ++ [{:format, :raw}, {:topic, nil}]
  end

  @impl true
  def init(%NodeModule.State{} = state, %Node{} = node) do
    %Options{} = options = node.opts
    state = %NodeModule.State{state | assigns: options}
    {:ok, state}
  end

  @impl true
  def handle_input(:message, %Message{} = message, %NodeModule.State{} = state) do
    topic =
      if state.assigns.topic == nil do
        message.topic
      else
        state.assigns.topic
      end

    raw_payload =
      case state.assigns.format do
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

    if topic == nil do
      error(state, "Message topic not supplied for outgoing message", %{})
    else
      topic = Enum.join(topic, "/")
      MqttPotion.publish(PenguinNodes.Mqtt, topic, raw_payload)
    end

    {:noreply, state}
  end

  @spec call(message :: NodeModule.input_value(), opts :: Options.t(), node_id :: Id.t()) ::
          Nodes.t()
  def call(message, %Options{} = opts, node_id) do
    NodeModule.call(__MODULE__, %{message: message}, opts, node_id)
  end
end
