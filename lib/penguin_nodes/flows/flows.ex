defmodule PenguinNodes.Flows do
  @moduledoc """
  Simple flows for testing nodes
  """
  use PenguinNodes.Nodes.Flow

  alias PenguinNodes.Flows
  import PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Nodes

  @spec generate_flow(id :: Id.t()) :: Nodes.t()
  def generate_flow(id) do
    Nodes.new()
    |> Nodes.merge(Flows.Test.generate_flow(id(:test)))
    |> Nodes.merge(Flows.Life360.generate_flow(id(:life360)))
    |> Nodes.merge(Flows.Tesla.generate_flow(1, id(:tesla)))
  end
end
