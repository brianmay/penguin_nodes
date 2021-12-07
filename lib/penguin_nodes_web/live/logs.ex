defmodule PenguinNodesWeb.Live.Logs do
  @moduledoc "Live view for Tesla"
  use PenguinNodesWeb, :live_view

  alias Phoenix.LiveView.Socket

  alias PenguinNodes.Config
  alias PenguinNodes.Nodes.Forward
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Node
  alias PenguinNodes.Nodes.Output
  alias PenguinNodesWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:nodes, %{})

    Endpoint.subscribe("logs")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    id =
      case params["id"] do
        nil -> nil
        id_str -> string_to_id(id_str)
      end

    socket = assign(socket, :id, id)
    {:noreply, socket}
  end

  @spec get_class(log :: map()) :: String.t() | nil
  defp get_class(%{level: :debug}), do: "alert-light"
  defp get_class(%{level: :info}), do: "alert-secondary"
  defp get_class(%{level: :notice}), do: "alert-primary"
  defp get_class(%{level: :warning}), do: "alert-warning"
  defp get_class(%{level: :error}), do: "alert-danger"
  defp get_class(_), do: nil

  @spec id_to_string(id :: Id.t()) :: String.t()
  defp id_to_string(id) do
    id
    |> Tuple.to_list()
    |> Enum.map_join("!", fn x -> Atom.to_string(x) end)
  end

  @spec string_to_id(str :: String.t()) :: Id.t()
  defp string_to_id(str) do
    str
    |> String.split("!")
    |> Enum.map(fn x -> String.to_existing_atom(x) end)
    |> List.to_tuple()
  end

  @spec get_list_url(Socket.t()) :: String.t()
  defp get_list_url(%Socket{} = socket) do
    Routes.logs_path(socket, :index)
  end

  @spec get_node_url(Socket.t(), id :: Id.t()) :: String.t()
  defp get_node_url(%Socket{} = socket, id) do
    id_str = id_to_string(id)
    Routes.logs_path(socket, :index, id_str)
  end

  @impl true
  def handle_info(%{topic: "logs", event: _, payload: %{level: :debug}}, socket) do
    {:noreply, socket}
  end

  def handle_info(%{topic: "logs", event: _, payload: payload}, socket) do
    nodes = socket.assigns.nodes
    key = payload.node_id

    lines = Map.get(nodes, key, [])
    lines = [payload | lines]
    lines = Enum.take(lines, 20)
    nodes = Map.put(nodes, key, lines)

    socket = assign(socket, :nodes, nodes)
    {:noreply, socket}
  end
end
