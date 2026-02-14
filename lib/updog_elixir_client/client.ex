defmodule UpdogElixirClient.Client do
  @moduledoc """
  HTTP client for sending data to the Updog server via Finch.
  All sends are fire-and-forget to avoid impacting the host app.
  """

  @behaviour UpdogElixirClient.HttpClient

  require Logger

  alias UpdogElixirClient.Config

  @impl true
  def post(url, body) when is_binary(body) do
    Task.start(fn ->
      headers = [
        {"content-type", "application/json"},
        {"x-api-key", Config.api_key()}
      ]

      request = Finch.build(:post, url, headers, body)

      case Finch.request(request, UpdogElixirClient.Finch, receive_timeout: 5_000) do
        {:ok, %{status: status}} when status in 200..299 ->
          :ok

        {:ok, %{status: status}} ->
          Logger.warning("[UpdogElixirClient] POST #{url} returned #{status}")

        {:error, reason} ->
          Logger.warning("[UpdogElixirClient] POST #{url} failed: #{inspect(reason)}")
      end
    end)
  end

  @impl true
  def post_json(url, data) do
    case Jason.encode(data) do
      {:ok, body} -> post(url, body)
      {:error, reason} -> Logger.warning("[UpdogElixirClient] JSON encode failed: #{inspect(reason)}")
    end
  end
end
