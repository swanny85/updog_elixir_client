defmodule UpdogClient.Notice do
  @moduledoc """
  Builds error notice payloads for the Updog API.
  """

  alias UpdogClient.{Backtrace, Config, Context, Breadcrumbs, Fingerprint}

  def build(exception, opts \\ []) when is_exception(exception) do
    stacktrace = Keyword.get(opts, :stacktrace, [])
    formatted_trace = Backtrace.format(stacktrace)

    %{
      error_class: inspect(exception.__struct__),
      message: Exception.message(exception),
      stacktrace: formatted_trace,
      breadcrumbs: Breadcrumbs.get(),
      context: Context.get(),
      request: Keyword.get(opts, :request, %{}),
      environment: Config.environment(),
      hostname: hostname(),
      fingerprint: Keyword.get(opts, :fingerprint)
    }
  end

  def build_from_error(kind, reason, stacktrace, opts \\ []) do
    formatted_trace = Backtrace.format(stacktrace)
    error_class = format_error_class(kind, reason)
    message = format_error_message(kind, reason)

    %{
      error_class: error_class,
      message: message,
      stacktrace: formatted_trace,
      breadcrumbs: Breadcrumbs.get(),
      context: Context.get(),
      request: Keyword.get(opts, :request, %{}),
      environment: Config.environment(),
      hostname: hostname(),
      fingerprint: Keyword.get(opts, :fingerprint)
    }
  end

  defp format_error_class(:error, %{__struct__: mod}), do: inspect(mod)
  defp format_error_class(:error, reason), do: inspect(reason)
  defp format_error_class(kind, _reason), do: to_string(kind)

  defp format_error_message(:error, reason) when is_exception(reason) do
    Exception.message(reason)
  end

  defp format_error_message(_kind, reason), do: inspect(reason)

  defp hostname do
    {:ok, name} = :inet.gethostname()
    to_string(name)
  end
end
