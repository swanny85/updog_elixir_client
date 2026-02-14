defmodule UpdogClient.VmPoller do
  @moduledoc """
  Collects BEAM VM metrics via telemetry_poller and sends them to Updog.

  Add to your application supervision tree:

      {UpdogClient.VmPoller, []}
  """

  use GenServer

  alias UpdogClient.Collector

  @vm_events [
    [:vm, :memory],
    [:vm, :total_run_queue_lengths],
    [:vm, :system_counts]
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    :telemetry.attach_many("updog-vm-metrics", @vm_events, &handle_vm_event/4, nil)
    {:ok, %{}}
  end

  def handle_vm_event([:vm, :memory], measurements, _metadata, _config) do
    hostname = get_hostname()

    Enum.each(measurements, fn {key, value} ->
      Collector.push_metric(%{
        name: "vm.memory.#{key}",
        value: value,
        hostname: hostname,
        tags: %{}
      })
    end)
  end

  def handle_vm_event([:vm, :total_run_queue_lengths], measurements, _metadata, _config) do
    hostname = get_hostname()

    Enum.each(measurements, fn {key, value} ->
      Collector.push_metric(%{
        name: "vm.run_queue.#{key}",
        value: value,
        hostname: hostname,
        tags: %{}
      })
    end)
  end

  def handle_vm_event([:vm, :system_counts], measurements, _metadata, _config) do
    hostname = get_hostname()

    Enum.each(measurements, fn {key, value} ->
      Collector.push_metric(%{
        name: "vm.system.#{key}",
        value: value,
        hostname: hostname,
        tags: %{}
      })
    end)
  end

  defp get_hostname do
    {:ok, name} = :inet.gethostname()
    to_string(name)
  end
end
