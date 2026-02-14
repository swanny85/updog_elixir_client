defmodule UpdogClient.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children =
      if UpdogClient.enabled?() do
        [
          {Finch, name: UpdogClient.Finch},
          UpdogClient.Collector,
          UpdogClient.TelemetryHandler
        ]
      else
        []
      end

    opts = [strategy: :one_for_one, name: UpdogClient.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
