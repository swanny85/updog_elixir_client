defmodule UpdogElixirClient.TelemetryHandler do
  @moduledoc """
  Attaches to Phoenix, Ecto, and Oban telemetry events.
  Forwards processed events to the Collector for batched sending.
  """

  alias UpdogElixirClient.{Collector, Config}

  require Logger

  def attach do
    :telemetry.attach(
      "updog-phoenix-endpoint",
      [:phoenix, :endpoint, :stop],
      &__MODULE__.handle_phoenix_event/4,
      nil
    )

    :telemetry.attach_many(
      "updog-phoenix-live-view",
      [
        [:phoenix, :live_view, :mount, :stop],
        [:phoenix, :live_view, :handle_event, :stop]
      ],
      &__MODULE__.handle_phoenix_event/4,
      nil
    )

    ecto_repos = Config.ecto_repos()

    Enum.each(ecto_repos, fn repo_path ->
      event = repo_path ++ [:query]
      id = "updog-ecto-#{Enum.join(repo_path, "-")}"
      :telemetry.attach(id, event, &__MODULE__.handle_ecto_event/4, nil)
    end)

    :telemetry.attach(
      "updog-oban",
      [:oban, :job, :stop],
      &__MODULE__.handle_oban_event/4,
      nil
    )
  end

  def handle_phoenix_event([:phoenix, :endpoint, :stop], measurements, metadata, _config) do
    try do
      if should_sample?() do
        duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)

        Collector.push_event(%{
          type: "trace",
          trace_id: generate_trace_id(),
          transaction_name: "#{metadata.conn.method} #{metadata.conn.request_path}",
          trace_type: "http",
          duration_ms: duration_ms,
          status_code: metadata.conn.status,
          method: metadata.conn.method,
          path: metadata.conn.request_path,
          started_at: DateTime.utc_now() |> DateTime.to_iso8601()
        })
      end
    rescue
      e ->
        Logger.warning("Updog endpoint telemetry handler error: #{inspect(e)}")
    end
  end

  def handle_phoenix_event([:phoenix, :live_view | _], measurements, metadata, _config) do
    try do
      if should_sample?() do
        duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
        view = metadata[:socket] && metadata[:socket].view

        Collector.push_event(%{
          type: "span",
          trace_id: generate_trace_id(),
          span_id: generate_span_id(),
          operation: "live_view",
          description: inspect(view || "unknown"),
          duration_ms: duration_ms,
          started_at: DateTime.utc_now() |> DateTime.to_iso8601()
        })
      end
    rescue
      e ->
        Logger.warning("Updog live_view telemetry handler error: #{inspect(e)}")
    end
  end

  def handle_phoenix_event(_, _, _, _), do: :ok

  def handle_ecto_event(_event, measurements, metadata, _config) do
    try do
      if should_sample?() do
        duration_ms = System.convert_time_unit(measurements.total_time || 0, :native, :millisecond)

        Collector.push_event(%{
          type: "span",
          trace_id: generate_trace_id(),
          span_id: generate_span_id(),
          operation: "ecto.query",
          description: metadata[:source] || "unknown",
          duration_ms: duration_ms,
          started_at: DateTime.utc_now() |> DateTime.to_iso8601()
        })
      end
    rescue
      e ->
        Logger.warning("Updog ecto telemetry handler error: #{inspect(e)}")
    end
  end

  def handle_oban_event(_event, measurements, metadata, _config) do
    try do
      if should_sample?() do
        duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)

        Collector.push_event(%{
          type: "span",
          trace_id: generate_trace_id(),
          span_id: generate_span_id(),
          operation: "oban.job",
          description: inspect(metadata[:worker]),
          duration_ms: duration_ms,
          started_at: DateTime.utc_now() |> DateTime.to_iso8601()
        })
      end
    rescue
      e ->
        Logger.warning("Updog oban telemetry handler error: #{inspect(e)}")
    end
  end

  defp should_sample? do
    :rand.uniform() <= Config.sample_rate()
  end

  defp generate_trace_id do
    :crypto.strong_rand_bytes(16) |> Base.hex_encode32(case: :lower, padding: false)
  end

  defp generate_span_id do
    :crypto.strong_rand_bytes(8) |> Base.hex_encode32(case: :lower, padding: false)
  end
end
