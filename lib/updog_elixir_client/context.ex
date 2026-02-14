defmodule UpdogElixirClient.Context do
  @moduledoc """
  Per-process context stored in Logger.metadata.
  Automatically cleaned up on process death.
  """

  @key :updog_context

  def set(data) when is_map(data) do
    existing = get()
    Logger.metadata([{@key, Map.merge(existing, data)}])
    :ok
  end

  def get do
    Logger.metadata()
    |> Keyword.get(@key, %{})
  end

  def clear do
    Logger.metadata([{@key, %{}}])
    :ok
  end
end
