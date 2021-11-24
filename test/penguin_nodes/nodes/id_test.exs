defmodule PenguinNodesWeb.Nodes.IdsTest do
  use ExUnit.Case

  alias PenguinNodes.Nodes.Id

  test "get_next_id works" do
    {:ok, pid} = Id.start_link(name: __MODULE__)
    assert :node_0 == Id.get_next_id(pid)
    assert :node_1 == Id.get_next_id(pid)
  end
end
