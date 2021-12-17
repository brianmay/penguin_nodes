defmodule PenguinNodesWeb.LayoutView do
  use PenguinNodesWeb, :view

  def link_class(active, item) when active == item do
    "py-4 px-2 text-green-500 border-b-4 border-green-500 font-semibold"
  end

  def link_class(_active, _item) do
    "py-4 px-2 text-gray-500 font-semibold hover:text-green-500 transition duration-300"
  end

  def mobile_link_class(active, item) when active == item do
    "block text-sm px-2 py-4 text-white bg-green-500 font-semibold"
  end

  def mobile_link_class(_active, _item) do
    "block text-sm px-2 py-4 hover:bg-green-500 transition duration-300"
  end

  def nav(assigns) do
    ~H"""
      <nav class="bg-white shadow-lg">
        <div class="max-w-6xl px-4 mx-auto">
            <div class="flex justify-between">
                <div class="flex space-x-7">
                    <div>
                        <!-- Website Logo -->
                        <a href="https://github.com/brianmay/penguin_nodes" class="flex items-center px-2 py-4">
                            <img src={Routes.static_path(@conn, "/images/logo.svg")} alt="Logo" class="mr-2">
                        </a>
                    </div>
                    <!-- Primary Navbar items -->
                    <div class="items-center hidden space-x-1 md:flex">
                        <%= live_redirect("Home", to: Routes.page_path(@conn, :index), class: link_class(@active, "home")) %>
                        <%= live_redirect("Logs", to: Routes.logs_path(@conn, :index), class: link_class(@active, "logs")) %>
                        <%= if PenguinNodesWeb.Auth.user_is_admin?(@user) do %>
                            <%= live_redirect("Dashboard", to: Routes.live_dashboard_path(@conn, :home), class: link_class(@active, "dashboard")) %>
                        <% end %>
                    </div>
                </div>
                <!-- Secondary Navbar items -->
                <div class="items-center hidden space-x-3 md:flex">
                    <%= if @user != nil do %>
                      <div class="relative group">
                          <button class={link_class(@active, "user")} data-dropdown-toggle="dropdown">
                              <%= @user["name"] %> <svg class="inline w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
                          </button>
                          <div id="dropdown" class="absolute left-0 hidden transition-all bg-white border border-2 border-gray-800 rounded opacity-0 w-60 top-full group-focus-within:block group-focus-within:opacity-100">
                              <%= link "Logout", to: Routes.page_path(@conn, :logout), method: :post, class: link_class(@active, "logout") %>
                          </div>
                      </div>
                    <% else %>
                          <%= live_redirect("Login", to: Routes.page_path(@conn, :login), class: link_class(@active, "login") ) %>
                    <% end %>
                </div>
                <!-- Mobile menu button -->
                <div class="flex items-center md:hidden">
                    <button class="outline-none mobile-menu-button">
                    <svg class="w-6 h-6 text-gray-500 hover:text-green-500"
                        x-show="!showMenu"
                        fill="none"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                    >
                        <path d="M4 6h16M4 12h16M4 18h16"></path>
                    </svg>
                </button>
                </div>
            </div>
        </div>
        <!-- mobile menu -->
        <div class="hidden mobile-menu">
            <ul class="">
                <%= live_redirect("Home", to: Routes.page_path(@conn, :index), class: mobile_link_class(@active, "home")) %>
                <%= live_redirect("Logs", to: Routes.logs_path(@conn, :index), class: mobile_link_class(@active, "logs")) %>
                <%= if PenguinNodesWeb.Auth.user_is_admin?(@user) do %>
                    <%= live_redirect("Dashboard", to: Routes.live_dashboard_path(@conn, :home), class: mobile_link_class(@active, "dashboard")) %>
                <% end %>
            </ul>
        </div>
        <script>
          const btn = document.querySelector("button.mobile-menu-button");
          const menu = document.querySelector(".mobile-menu");

          btn.addEventListener("click", () => {
              menu.classList.toggle("hidden");
          });
      </script>
    </nav>
    """
  end
end
