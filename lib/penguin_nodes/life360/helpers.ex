defmodule PenguinNodes.Life360.Helpers do
  @moduledoc """
  HTTP wrapper functions for Life360
  """
  @spec login :: {:error, String.t() | Mojito.Error.t()} | {:ok, map()}
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

    case Mojito.post(url, headers, payload) do
      {:ok, %Mojito.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %Mojito.Response{status_code: status_code}} ->
        {:error, "Unexpected response #{status_code}"}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec list_circles(login :: map()) :: {:error, String.t() | Mojito.Error.t()} | {:ok, map()}
  def list_circles(login) do
    token = login["access_token"]
    url = "https://www.life360.com/v3/circles"

    headers = [
      {"accept", "application/json"},
      {"authorization", "Bearer #{token}"}
    ]

    case Mojito.get(url, headers) do
      {:ok, %Mojito.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %Mojito.Response{status_code: status_code}} ->
        {:error, "Unexpected response #{status_code}"}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec get_circle_info(login :: map(), circle :: map()) ::
          {:error, String.t() | Mojito.Error.t()} | {:ok, map()}
  def get_circle_info(login, circle) do
    token = login["access_token"]
    circle_id = circle["id"]
    url = "https://www.life360.com/v3/circles/#{circle_id}"

    headers = [
      {"accept", "application/json"},
      {"authorization", "Bearer #{token}"}
    ]

    case Mojito.get(url, headers) do
      {:ok, %Mojito.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %Mojito.Response{status_code: status_code}} ->
        {:error, "Unexpected response #{status_code}"}

      {:error, error} ->
        {:error, error}
    end
  end
end