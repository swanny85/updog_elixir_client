defmodule UpdogElixirClient.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: UpdogElixirClient.Finch},
      UpdogElixirClient.Collector,
      UpdogElixirClient.TelemetryHandler
    ]

    opts = [strategy: :one_for_one, name: UpdogElixirClient.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
