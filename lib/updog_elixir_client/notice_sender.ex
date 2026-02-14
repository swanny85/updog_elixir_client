defmodule UpdogElixirClient.NoticeSender do
  @moduledoc """
  Sends error notices immediately to the Updog server.
  """

  alias UpdogElixirClient.{Config, Notice}

  def send_notice(exception, opts \\ []) do
    payload = Notice.build(exception, opts)
    http_client().post_json(Config.notices_url(), payload)
  end

  def send_error(kind, reason, stacktrace, opts \\ []) do
    payload = Notice.build_from_error(kind, reason, stacktrace, opts)
    http_client().post_json(Config.notices_url(), payload)
  end

  defp http_client do
    Application.get_env(:updog_elixir_client, :http_client, UpdogElixirClient.Client)
  end
end
