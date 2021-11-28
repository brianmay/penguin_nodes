defmodule PenguinNodes.Mqtt.Message do
  @moduledoc """
  Options for the timer node
  """
  @type t :: %__MODULE__{
          topic: list(String.t()),
          payload: map()
        }
  @enforce_keys [:topic, :payload]
  defstruct @enforce_keys
end
