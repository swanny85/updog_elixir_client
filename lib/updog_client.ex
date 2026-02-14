defmodule UpdogClient do
  @moduledoc """
  Public API for the Updog APM client.

  ## Configuration

      config :updog_client,
        api_key: System.fetch_env!("UPDOG_API_KEY"),
        endpoint: System.fetch_env!("UPDOG_ENDPOINT"),
        environment: config_env(),
        sample_rate: 1.0,
        enabled: true
  """

  alias UpdogClient.{NoticeSender, Context, Breadcrumbs, Collector}

  @doc """
  Report an error to Updog. Errors are sent immediately, never batched.
  """
  def notify(exception, opts \\ []) when is_exception(exception) do
    if enabled?() do
      NoticeSender.send_notice(exception, opts)
    end

    :ok
  end

  @doc """
  Report an error from a kind/reason/stacktrace tuple.
  """
  def notify_error(kind, reason, stacktrace, opts \\ []) do
    if enabled?() do
      NoticeSender.send_error(kind, reason, stacktrace, opts)
    end

    :ok
  end

  @doc """
  Set context data for the current process. Attached to all errors from this process.
  """
  def context(data) when is_map(data) do
    Context.set(data)
  end

  @doc """
  Add a breadcrumb to the current process trail.
  """
  def add_breadcrumb(message, metadata \\ %{}) do
    Breadcrumbs.add(message, metadata)
  end

  @doc """
  Manually report a telemetry event for batched sending.
  """
  def report_event(event) when is_map(event) do
    if enabled?() do
      Collector.push_event(event)
    end

    :ok
  end

  @doc """
  Returns whether the client is enabled.
  """
  def enabled? do
    Application.get_env(:updog_client, :enabled, true)
  end
end
