defmodule PenguinNodesWeb.Live.Tesla do
  @moduledoc "Live view for Tesla"
  use PenguinNodesWeb, :live_view

  def mount(_params, _session, socket) do
    PenguinNodes.Tesla.register(self())
    {active_conditions, tesla_state} = PenguinNodes.Tesla.get_tesla_state()

    socket =
      socket
      |> assign(:tesla_state, tesla_state)
      |> assign(:active_conditions, active_conditions)
      |> assign(:active, "tesla")

    {:ok, socket}
  end

  def handle_cast({:update_tesla_state, active_conditions, tesla_state}, socket) do
    socket = assign(socket, :tesla_state, tesla_state)
    socket = assign(socket, :active_conditions, active_conditions)
    {:noreply, socket}
  end
end
