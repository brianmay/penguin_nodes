defmodule PenguinNodes.Flows.Life360 do
  @moduledoc """
  Simple flows for testing nodes
  """
  use PenguinNodes.Nodes.Flow

  import PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Life360.Circles
  alias PenguinNodes.Nodes.Mqtt
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Nodes.Simple

  defmodule Changed do
    @moduledoc """
    NQTT Message
    """
    @type t :: %__MODULE__{
            old_location: String.t(),
            location: String.t(),
            changed: boolean(),
            person: map()
          }
    @enforce_keys [:old_location, :location, :changed, :person]
    defstruct @enforce_keys
  end

  @spec life360_location_changed(person :: map(), acc :: map()) ::
          {person :: Changed.t() | nil, acc :: map}
  defp life360_location_changed(person, acc) do
    id = person["id"]
    location = person["location"]["name"]

    out =
      case Map.fetch(acc, id) do
        {:ok, old_location} ->
          %Changed{
            old_location: old_location,
            location: location,
            changed: old_location != location,
            person: person
          }

        :error ->
          %Changed{
            old_location: nil,
            location: location,
            changed: false,
            person: person
          }
      end

    acc = Map.put(acc, id, location)
    {out, acc}
  end

  @spec filter_changed(changed :: Changed.t()) :: boolean()
  def filter_changed(%Changed{changed: x}), do: x

  @spec changed_to_message(changed :: Changed.t()) :: String.t()
  def changed_to_message(%Changed{} = changed) do
    name = "#{changed.person["firstName"]} #{changed.person["lastName"]}"

    case changed do
      %{old_location: nil, location: location} -> "#{name} has arrived at #{location}"
      %{old_location: location, location: nil} -> "#{name} has left #{location}"
      %{old_location: old, location: new} -> "#{name} has left #{old} and arrived at #{new}"
    end
  end

  @spec changed_to_mqtt_message(changed :: Changed.t()) :: Mqtt.Message.t()
  def changed_to_mqtt_message(%Changed{} = changed) do
    %Mqtt.Message{
      payload: changed.person,
      topic: ["life360", changed.person["id"]]
    }
  end

  @spec generate_flow(id :: Id.t()) :: Nodes.t()
  def generate_flow(id) do
    nodes = Nodes.new()

    circles =
      call_value(nil, Circles, %{}, id(:circles))
      |> call_value(
        Simple.Reduce,
        %{func: &life360_location_changed/2, acc: %{}},
        id(:location_changed)
      )

    circles
    |> call_value(Simple.Map, %{func: &changed_to_mqtt_message/1}, id(:mqtt_message))
    |> mqtt_out(id(:mqtt_out))
    |> terminate()

    circles
    |> call_value(Simple.Filter, %{func: &filter_changed/1}, id(:filter_changed))
    |> call_value(Simple.Map, %{func: &changed_to_message/1}, id(:changed_to_message))
    |> message(id(:message))
    |> terminate()

    nodes
  end
end
