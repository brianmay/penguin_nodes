defmodule PenguinNodes.Flows.Google do
  @moduledoc """
  Simple flows for testing nodes
  """
  use PenguinNodes.Nodes.Flow

  import PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Mqtt
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Nodes.Robotica
  alias PenguinNodes.Nodes.Simple

  @type power_status :: boolean() | :offline | :unknown

  @spec light_google_to_robotica(Mqtt.Message.t(), String.t(), String.t()) :: Mqtt.Message.t()
  def light_google_to_robotica(message, location, device) do
    input = message.payload

    color = %{
      "hue" => 0,
      "saturation" => 0,
      "brightness" => 100,
      "kelvin" => 3500
    }

    color =
      if Map.has_key?(input, "hue") do
        Map.put(color, "hue", input["hue"])
      else
        color
      end

    color =
      if Map.has_key?(input, "saturation") do
        Map.put(color, "saturation", input["saturation"])
      else
        color
      end

    color =
      if Map.has_key?(input, "brightness") do
        Map.put(color, "brightness", input["brightness"])
      else
        color
      end

    color =
      if Map.has_key?(input, "temperature") do
        Map.put(color, "kelvin", input["temperature"])
      else
        color
      end

    scene =
      case {location, device} do
        {"Brian", "Light"} -> "auto"
        {_, _} -> "default"
      end

    action = if input["on"], do: nil, else: "turn_off"

    payload = %{
      "action" => action,
      "color" => color,
      "scene" => scene
    }

    %Mqtt.Message{
      payload: payload,
      topic: ["command", location, device]
    }
  end

  @spec light_robotica_to_google(String.t(), String.t(), String.t()) :: Mqtt.Message.t()
  def light_robotica_to_google(data, location, device) do
    payload =
      case data do
        "ON" -> %{"on" => true, "online" => true}
        "OFF" -> %{"on" => false, "online" => true}
        "HARD_OFF" -> %{"on" => false, "online" => false}
        "ERROR" -> %{"on" => false, "online" => false}
      end

    %Mqtt.Message{
      payload: payload,
      topic: ["google", location, device, "in"]
    }
  end

  @spec timer_to_auto(atom(), String.t(), String.t()) :: Mqtt.Message.t()
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def timer_to_auto(_data, location, device) do
    timezone = "Australia/Melbourne"
    now = DateTime.now!(timezone)

    color =
      case now.hour do
        h when h >= 22 or h < 5 ->
          %{hue: 0, saturation: 0, brightness: 5, kelvin: 1000}

        h when h >= 21 or h < 6 ->
          %{hue: 0, saturation: 0, brightness: 15, kelvin: 1500}

        h when h >= 20 or h < 7 ->
          %{hue: 0, saturation: 0, brightness: 25, kelvin: 2000}

        h when h >= 19 or h < 8 ->
          %{hue: 0, saturation: 0, brightness: 50, kelvin: 2500}

        h when h >= 18 or h < 9 ->
          %{hue: 0, saturation: 0, brightness: 100, kelvin: 3000}

        _ ->
          %{hue: 0, saturation: 0, brightness: 100, kelvin: 3500}
      end

    payload = %{
      "power" => "ON",
      "color" => color
    }

    %Mqtt.Message{
      payload: payload,
      topic: ["command", location, device, "scene", "auto"]
    }
  end

  @spec device_google_to_robotica(Mqtt.Message.t(), String.t(), String.t()) :: Mqtt.Message.t()
  def device_google_to_robotica(message, location, device) do
    input = message.payload

    action = if input["on"], do: "turn_on", else: "turn_off"

    payload = %{
      "action" => action
    }

    %Mqtt.Message{
      payload: payload,
      topic: ["command", location, device]
    }
  end

  @spec device_robotica_to_google(String.t(), String.t(), String.t()) :: Mqtt.Message.t()
  def device_robotica_to_google(data, location, device) do
    payload =
      case data do
        "ON" -> %{"on" => true, "online" => true}
        "OFF" -> %{"on" => false, "online" => true}
        "HARD_OFF" -> %{"on" => false, "online" => false}
        "ERROR" -> %{"on" => false, "online" => false}
      end

    %Mqtt.Message{
      payload: payload,
      topic: ["google", location, device, "in"]
    }
  end

  @spec light(location :: String.t(), device :: String.t(), id :: Id.t()) :: Nodes.t()
  def light(location, device, id) do
    nodes = Nodes.new()

    mqtt_in(["google", location, device, "out"], :json, :no_resend, id(:google_in))
    |> call_value(
      Simple.Map,
      %{func: &light_google_to_robotica(&1, location, device)},
      id(:google_to_robotica)
    )
    |> mqtt_out(id(:robotica_out))
    |> terminate()

    # night =
    #   mqtt_in(["state", light, "Night", "power"], :raw, id(:night_in))
    #   |> payload(id(:night_in_payload))

    power =
      mqtt_in(["state", location, device, "power"], :raw, id(:power_in))
      |> payload(id(:power_payload))

    priorities =
      mqtt_in(["state", location, device, "priorities"], :json, id(:priorities_in))
      |> payload(id(:priorities_payload))

    %{power: power, priorities: priorities}
    |> call_value(Robotica.Power, %{}, id(:get_power))
    |> call_value(
      Simple.Map,
      %{func: &light_robotica_to_google(&1, location, device)},
      id(:robotica_to_google)
    )
    |> mqtt_out(id(:google_out))
    |> terminate()

    call_value(Simple.Timer, %{initial: :start, interval: 60_000}, id(:auto_timer))
    |> call_value(Simple.Map, %{func: &timer_to_auto(&1, location, device)}, id(:auto_map))
    |> call_value(Simple.Debug, %{message: "Updating auto"}, id(:auto_debug))
    |> mqtt_out(true, id(:auto_out))
    |> terminate()

    nodes
  end

  @spec device(location :: String.t(), device :: String.t(), id :: Id.t()) :: Nodes.t()
  def device(location, device, id) do
    nodes = Nodes.new()

    mqtt_in(["google", location, device, "out"], :json, id(:google_in))
    |> call_value(
      Simple.Map,
      %{func: &device_google_to_robotica(&1, location, device)},
      id(:google_to_robotica)
    )
    |> mqtt_out(id(:robotica_out))
    |> terminate()

    mqtt_in(["state", location, device, "power"], :raw, id(:power_in))
    |> payload(id(:power_payload))
    |> call_value(
      Simple.Map,
      %{func: &device_robotica_to_google(&1, location, device)},
      id(:robotica_to_google)
    )
    |> mqtt_out(id(:google_out))
    |> terminate()

    nodes
  end

  @spec generate_flow(id :: Id.t()) :: Nodes.t()
  def generate_flow(id) do
    nodes = Nodes.new()

    light("Brian", "Light", id(:brian_light))
    |> terminate()

    device("Brian", "Fan", id(:brian_fan))
    |> terminate()

    light("Dining", "Light", id(:dining_light))
    |> terminate()

    device("Dining", "TvSwitch", id(:dining_tv_switch))
    |> terminate()

    light("Passage", "Light", id(:passage_light))
    |> terminate()

    light("Twins", "Light", id(:twins_light))
    |> terminate()

    light("Akira", "Light", id(:akira_light))
    |> terminate()

    light("Jan", "Light", id(:jan_light))
    |> terminate()

    nodes
  end
end
