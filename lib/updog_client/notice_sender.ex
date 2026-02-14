defmodule UpdogClient.NoticeSender do
  @moduledoc """
  Sends error notices immediately to the Updog server.
  """

  alias UpdogClient.{Client, Config, Notice}

  def send_notice(exception, opts \\ []) do
    payload = Notice.build(exception, opts)
    Client.post_json(Config.notices_url(), payload)
  end

  def send_error(kind, reason, stacktrace, opts \\ []) do
    payload = Notice.build_from_error(kind, reason, stacktrace, opts)
    Client.post_json(Config.notices_url(), payload)
  end
end
