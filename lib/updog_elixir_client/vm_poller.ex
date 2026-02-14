defmodule UpdogElixirClient.VmPoller do
  @moduledoc """
  Attaches to BEAM VM telemetry events and sends metrics to Updog.
  """

  alias UpdogElixirClient.Collector

  @vm_events [
    [:vm, :memory],
    [:vm, :total_run_queue_lengths],
    [:vm, :system_counts]
  ]

  def attach do
    :telemetry.attach_many("updog-vm-metrics", @vm_events, &__MODULE__.handle_vm_event/4, nil)
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
