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
      |> assign(:active, "logs")

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
  defp get_class(%{level: :debug}), do: "border-b alert-debug"
  defp get_class(%{level: :info}), do: "border-b alert-info"
  defp get_class(%{level: :notice}), do: "border-b alert-notice"
  defp get_class(%{level: :warning}), do: "border-b alert-warning"
  defp get_class(%{level: :error}), do: "border-b alert-error"
  defp get_class(_), do: "border-b"

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

  def logs(assigns) do
    lines = Map.fetch!(assigns, :lines)

    ~H"""
        <table class="w-full border-b border-gray-200 dark:border-black shadow-lg table-fixed">
            <thead class="text-white bg-black dark:bg-gray-500 dark:text-black">
                <th class="w-40">Time</th>
                <th class="hidden w-40 border-l border-white dark:border-black lg:table-cell">Level</th>
                <th class="hidden w-40 border-l border-white dark:border-black lg:table-cell">Hostname</th>
                <th class="border-l border-white dark:border-black w-50">Message</th>
                <th class="hidden border-l border-white dark:border-black w-50 md:table-cell">Values</th>
                <th class="hidden border-l border-white dark:border-black w-50 md:table-cell">State</th>
            </thead>

            <tbody>
                <%= for line <- lines do %>
                    <tr class={get_class(line)}>
                        <td class=""><%= line.datetime |> DateTime.shift_zone!("Australia/Melbourne") |> Calendar.strftime("%Y-%m-%d %H:%M:%S") %></td>
                        <td class="hidden border-l lg:table-cell"><%= inspect line.level %></td>
                        <td class="hidden border-l lg:table-cell"><%= line.hostname %></td>
                        <td class="border-l"><%= line.message %></td>
                        <td class="hidden border-l md:table-cell">
                            <div class="hover">
                                <div class="truncate trigger"><%= inspect(line.values) |> String.slice(0..30) %></div>
                                <div class="tooltip"><pre><%= inspect(line.values, pretty: true) %></pre></div>
                            </div>
                        </td>
                        <td class="hidden border-l md:table-cell">
                            <div class="hover">
                                <div class="truncate trigger"><%= inspect(line.state) |> String.slice(0..30) %></div>
                                <div class="tooltip"><pre><%= inspect(line.state, pretty: true) %></pre></div>
                            </div>
                        </td>
                    </tr>
                <% end %>
            </tbody>
        </table>
    """
  end
end
