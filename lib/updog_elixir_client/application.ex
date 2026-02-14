defmodule UpdogElixirClient.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children =
      if UpdogElixirClient.enabled?() do
        [
          {Finch, name: UpdogElixirClient.Finch},
          UpdogElixirClient.Collector,
          UpdogElixirClient.TelemetryHandler
        ]
      else
        []
      end

    opts = [strategy: :one_for_one, name: UpdogElixirClient.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
