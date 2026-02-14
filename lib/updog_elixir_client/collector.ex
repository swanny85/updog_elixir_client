defmodule UpdogElixirClient.Collector do
  @moduledoc """
  GenServer that buffers telemetry events and logs, flushing them
  in batches to the Updog server.
  """

  use GenServer

  alias UpdogElixirClient.Config

  @flush_interval 5_000
  @max_batch_size 100

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def push_event(event) do
    GenServer.cast(__MODULE__, {:event, event})
  end

  def push_log(log) do
    GenServer.cast(__MODULE__, {:log, log})
  end

  def push_metric(metric) do
    GenServer.cast(__MODULE__, {:metric, metric})
  end

  @impl true
  def init(_opts) do
    schedule_flush()
    {:ok, %{events: [], logs: [], metrics: []}}
  end

  @impl true
  def handle_cast({:event, event}, state) do
    events = [event | state.events]

    if length(events) >= @max_batch_size do
      flush_events(events)
      {:noreply, %{state | events: []}}
    else
      {:noreply, %{state | events: events}}
    end
  end

  @impl true
  def handle_cast({:log, log}, state) do
    logs = [log | state.logs]

    if length(logs) >= @max_batch_size do
      flush_logs(logs)
      {:noreply, %{state | logs: []}}
    else
      {:noreply, %{state | logs: logs}}
    end
  end

  @impl true
  def handle_cast({:metric, metric}, state) do
    metrics = [metric | state.metrics]

    if length(metrics) >= @max_batch_size do
      flush_metrics(metrics)
      {:noreply, %{state | metrics: []}}
    else
      {:noreply, %{state | metrics: metrics}}
    end
  end

  @impl true
  def handle_info(:flush, state) do
    if state.events != [], do: flush_events(state.events)
    if state.logs != [], do: flush_logs(state.logs)
    if state.metrics != [], do: flush_metrics(state.metrics)

    schedule_flush()
    {:noreply, %{events: [], logs: [], metrics: []}}
  end

  defp schedule_flush do
    Process.send_after(self(), :flush, @flush_interval)
  end

  defp flush_events(events) do
    http_client().post_json(Config.events_url(), %{events: Enum.reverse(events)})
  end

  defp flush_logs(logs) do
    http_client().post_json(Config.logs_url(), %{logs: Enum.reverse(logs)})
  end

  defp flush_metrics(metrics) do
    http_client().post_json(Config.metrics_url(), %{metrics: Enum.reverse(metrics)})
  end

  defp http_client do
    Application.get_env(:updog_elixir_client, :http_client, UpdogElixirClient.Client)
  end
end
