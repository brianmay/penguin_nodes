defmodule PenguinNodes.Nodes.Life360.Helpers do
  @moduledoc """
  HTTP wrapper functions for Life360
  """
  @spec process_response({:ok, Finch.Response.t()} | {:error, Finch.Error.t()}) ::
          {:error, String.t() | Finch.Error.t()} | {:ok, map()}
  defp process_response(response) do
    case response do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, body} -> {:ok, body}
          {:error, reason} -> {:error, "Cannot decode json: #{inspect(reason)}"}
        end

      {:ok, %Finch.Response{status: status_code}} ->
        {:error, "Unexpected response #{status_code}"}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec login :: {:error, String.t() | Finch.Error.t()} | {:ok, map()}
  def login do
    url = "https://www.life360.com/v3/oauth2/token"
    config = Application.get_env(:penguin_nodes, :life360)
    username = config.username
    password = config.password

    headers = [
      {"accept", "application/json"},
      {"content-type", "application/x-www-form-urlencoded"},
      {"authorization",
       "Basic U3dlcUFOQWdFVkVoVWt1cGVjcmVrYXN0ZXFhVGVXckFTV2E1dXN3MzpXMnZBV3JlY2hhUHJlZGFoVVJhZ1VYYWZyQW5hbWVqdQ=="}
    ]

    payload = "username=#{username}&password=#{password}&grant_type=password"

    Finch.build(:post, url, headers, payload)
    |> Finch.request(PenguinNodes.Finch)
    |> process_response()
  end

  @spec list_circles(login :: map()) :: {:error, String.t() | Finch.Error.t()} | {:ok, map()}
  def list_circles(login) do
    token = login["access_token"]
    url = "https://www.life360.com/v3/circles"

    headers = [
      {"accept", "application/json"},
      {"authorization", "Bearer #{token}"}
    ]

    Finch.build(:get, url, headers)
    |> Finch.request(PenguinNodes.Finch)
    |> process_response()
  end

  @spec get_circle_info(login :: map(), circle :: map()) ::
          {:error, String.t() | Finch.Error.t()} | {:ok, map()}
  def get_circle_info(login, circle) do
    token = login["access_token"]
    circle_id = circle["id"]
    url = "https://www.life360.com/v3/circles/#{circle_id}"

    headers = [
      {"accept", "application/json"},
      {"authorization", "Bearer #{token}"}
    ]

    Finch.build(:get, url, headers)
    |> Finch.request(PenguinNodes.Finch)
    |> process_response()
  end
end
