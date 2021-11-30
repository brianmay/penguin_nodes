defmodule PenguinNodes.Flows.Helpers do
  @moduledoc """
  Simple flows for testing nodes
  """
  require PenguinNodes.Nodes.Flow

  alias PenguinNodes.Mqtt
  import PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Id
  import PenguinNodes.Nodes.Flow
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Nodes.Wire
  alias PenguinNodes.Simple

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

  @spec filter_nils(any()) :: boolean()
  defp filter_nils(nil), do: false
  defp filter_nils(_), do: true

  @spec message(wire :: Wire.t(), id :: Id.t()) :: Nodes.t()
  def message(%Wire{} = wire, id) do
    wire
    |> call_with_value(Simple.Map, %{map_func: &string_to_command/1}, id(:string_to_command))
    |> call_with_value(Mqtt.Out, %{format: :json}, id(:out))
  end

  @spec filter_nils(wire :: Wire.t(), id :: Id.t()) :: Nodes.t()
  def filter_nils(%Wire{} = wire, id) do
    wire
    |> call_with_value(Simple.Filter, %{func: &filter_nils/1}, id)
  end
end
