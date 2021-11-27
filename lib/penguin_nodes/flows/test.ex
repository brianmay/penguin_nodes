defmodule PenguinNodes.Flows.Test do
  @moduledoc """
  Simple flows for testing nodes
  """
  require PenguinNodes.Nodes.Id

  import PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Simple

  @spec generate_test_flow(id :: Id.t()) :: Nodes.t()
  def generate_test_flow(id) do
    timer1 = Simple.Timer.call(%Simple.Timer.Options{data: 10}, id(id, :timer1))
    timer2 = Simple.Timer.call(%Simple.Timer.Options{data: 20}, id(id, :timer2))
    debug1 = Simple.Debug.call([timer1], %Simple.Debug.Options{}, id(id, :debug1))
    debug2 = Simple.Debug.call([timer1, timer2], %Simple.Debug.Options{}, id(id, :debug2))

    Nodes.new()
    |> Nodes.merge(debug1)
    |> Nodes.merge(debug2)
    |> Nodes.build()
  end

  @spec test_flow() :: Macro.t()
  defmacro test_flow do
    Macro.escape(__MODULE__.generate_test_flow({}))
  end
end
