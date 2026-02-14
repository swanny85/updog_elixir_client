defmodule UpdogElixirClient.Breadcrumbs do
  @moduledoc """
  Per-process breadcrumb trail stored in Logger.metadata.
  """

  @key :updog_breadcrumbs
  @max_breadcrumbs 40

  def add(message, metadata \\ %{}) do
    crumb = %{
      message: message,
      metadata: metadata,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    existing = Logger.metadata() |> Keyword.get(@key, [])
    updated = Enum.take([crumb | existing], @max_breadcrumbs)
    Logger.metadata([{@key, updated}])
    :ok
  end

  def get do
    Logger.metadata()
    |> Keyword.get(@key, [])
    |> Enum.reverse()
  end

  def clear do
    Logger.metadata([{@key, []}])
    :ok
  end
end
