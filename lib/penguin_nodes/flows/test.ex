defmodule PenguinNodes.Flows.Test do
  @moduledoc """
  Simple flows for testing nodes
  """
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Simple

  @spec generate_test_flow :: Nodes.t()
  def generate_test_flow do
    timer1 = Simple.Timer.call(%Simple.Timer.Options{data: 10})
    timer2 = Simple.Timer.call(%Simple.Timer.Options{data: 20})
    debug1 = Simple.Debug.call([timer1], %Simple.Debug.Options{})
    debug2 = Simple.Debug.call([timer1, timer2], %Simple.Debug.Options{})

    Nodes.new()
    |> Nodes.merge(debug1)
    |> Nodes.merge(debug2)
    |> Nodes.build()
  end

  @spec test_flow() :: Macro.t()
  defmacro test_flow do
    Macro.escape(__MODULE__.generate_test_flow())
  end
end
