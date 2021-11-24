defmodule PenguinNodes.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  defp get_client_id do
    {:ok, hostname} = :inet.gethostname()
    hostname = to_string(hostname)
    "penguin_nodes-#{hostname}"
  end

  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies)

    # List all child processes to be supervised

    mqtt_host = Application.get_env(:penguin_nodes, :mqtt_host)
    mqtt_port = Application.get_env(:penguin_nodes, :mqtt_port)
    ca_cert_file = Application.get_env(:penguin_nodes, :ca_cert_file)
    user_name = Application.get_env(:penguin_nodes, :mqtt_user_name)
    password = Application.get_env(:penguin_nodes, :mqtt_password)

    children = [
      {Cluster.Supervisor, [topologies, [name: PenguinNodes.ClusterSupervisor]]},
      # Start the Ecto repository
      PenguinNodes.Repo,
      PenguinNodesWeb.Telemetry,
      # Start the endpoint when the application starts
      PenguinNodesWeb.Endpoint,
      {Phoenix.PubSub, [name: PenguinNodes.PubSub, adapter: Phoenix.PubSub.PG2]},
      {MqttPotion.Connection,
       name: PenguinNodes.Mqtt,
       host: mqtt_host,
       port: mqtt_port,
       ssl: true,
       protocol_version: 5,
       client_id: get_client_id(),
       username: user_name,
       password: password,
       tcp_opts: [
         :inet6
       ],
       ssl_opts: [
         verify: :verify_peer,
         cacertfile: ca_cert_file
       ],
       handler: PenguinNodes.MqttHandler,
       subscriptions: []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PenguinNodes.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PenguinNodesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
