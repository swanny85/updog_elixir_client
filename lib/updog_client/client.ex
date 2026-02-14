defmodule UpdogClient.Client do
  @moduledoc """
  HTTP client for sending data to the Updog server via Finch.
  All sends are fire-and-forget to avoid impacting the host app.
  """

  require Logger

  alias UpdogClient.Config

  def post(url, body) when is_binary(body) do
    Task.start(fn ->
      headers = [
        {"content-type", "application/json"},
        {"x-api-key", Config.api_key()}
      ]

      request = Finch.build(:post, url, headers, body)

      case Finch.request(request, UpdogClient.Finch, receive_timeout: 5_000) do
        {:ok, %{status: status}} when status in 200..299 ->
          :ok

        {:ok, %{status: status}} ->
          Logger.warning("[UpdogClient] POST #{url} returned #{status}")

        {:error, reason} ->
          Logger.warning("[UpdogClient] POST #{url} failed: #{inspect(reason)}")
      end
    end)
  end

  def post_json(url, data) do
    case Jason.encode(data) do
      {:ok, body} -> post(url, body)
      {:error, reason} -> Logger.warning("[UpdogClient] JSON encode failed: #{inspect(reason)}")
    end
  end
end
