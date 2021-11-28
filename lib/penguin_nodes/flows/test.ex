defmodule PenguinNodes.Flows.Test do
  @moduledoc """
  Simple flows for testing nodes
  """
  require PenguinNodes.Nodes.Id

  alias PenguinNodes.Mqtt
  import PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Nodes.Wire
  alias PenguinNodes.Simple.Changed
  alias PenguinNodes.Simple.Debug
  alias PenguinNodes.Simple.Map
  alias PenguinNodes.Simple.Timer

  @type power_status :: boolean() | :offline | :unknown

  @spec power_to_boolean(Mqtt.Message.t()) :: power_status()
  defp power_to_boolean(%Mqtt.Message{payload: "OFF"}), do: false
  defp power_to_boolean(%Mqtt.Message{payload: "HARD_OFF"}), do: :offline
  defp power_to_boolean(%Mqtt.Message{payload: "ON"}), do: true
  defp power_to_boolean(%Mqtt.Message{}), do: :unknown

  @spec power_status_to_message(Changed.Message.t()) :: String.t()
  defp power_status_to_message(%Changed.Message{new: true}), do: "The fan has been turned on"
  defp power_status_to_message(%Changed.Message{new: false}), do: "The fan has been turned off"

  defp power_status_to_message(%Changed.Message{new: :offline}),
    do: "The fan has been turned off at the power point"

  defp power_status_to_message(%Changed.Message{new: :unknown}), do: "The fan state is unknown"

  @spec string_to_command(String.t()) :: Mqtt.Message.t()
  defp string_to_command(message) do
    %Mqtt.Message{
      payload: [
        %{
          "locations" => ["Brian"],
          "devices" => ["Robotica"],
          "command" => %{
            "message" => %{
              text: message
            }
          }
        }
      ],
      topic: ["execute"]
    }
  end

  @spec message(wire :: Wire.t(), id :: Id.t()) :: Nodes.t()
  defp message(%Wire{} = wire, id) do
    wire
    |> Map.call(%Map.Options{map_func: &string_to_command/1}, id(id, :string_to_command))
    |> Mqtt.Out.call(%Mqtt.Out.Options{format: :json}, id(id, :out))
  end

  @spec generate_test_flow(id :: Id.t()) :: Nodes.t()
  def generate_test_flow(id) do
    timer1 = Timer.call(%Timer.Options{data: 10, interval: 10_000}, id(id, :timer1))

    message =
      Mqtt.In.call(%Mqtt.In.Options{topic: ["state", "Brian", "Fan", "power"]}, id(id, :mqtt))
      |> Map.call(%Map.Options{map_func: &power_to_boolean/1}, id(id, :power_to_boolean))
      |> Changed.call(%Changed.Options{}, id(id, :changed))
      |> Map.call(%Map.Options{map_func: &power_status_to_message/1}, id(id, :power_to_string))

    output_node =
      message
      |> message(id(id, :message))

    debug1_node = Debug.call([timer1], %Debug.Options{}, id(id, :debug1))
    debug2_node = Debug.call([message], %Debug.Options{}, id(id, :debug2))

    Nodes.new()
    |> Nodes.merge(debug1_node)
    |> Nodes.merge(debug2_node)
    |> Nodes.merge(output_node)
    |> Nodes.build()
  end

  # @spec test_flow() :: Macro.t()
  # defmacro test_flow do
  #   Macro.escape(__MODULE__.generate_test_flow({}))
  # end
end
