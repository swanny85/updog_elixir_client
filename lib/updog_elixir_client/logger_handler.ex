defmodule UpdogElixirClient.LoggerHandler do
  @moduledoc """
  Erlang :logger handler that captures crash reports and sends them to Updog.

  Add to your application start:

      :logger.add_handler(:updog, UpdogElixirClient.LoggerHandler, %{})
  """

  @behaviour :logger_handler

  @impl true
  def log(%{level: level, msg: msg, meta: meta}, _config)
      when level in [:error, :critical, :alert, :emergency] do
    case msg do
      {:report, %{reason: {exception, stacktrace}}} when is_exception(exception) ->
        UpdogElixirClient.notify(exception, stacktrace: stacktrace)

      {:report, %{reason: {{kind, reason}, stacktrace}}} when is_list(stacktrace) ->
        UpdogElixirClient.notify_error(kind, reason, stacktrace)

      {:string, message} ->
        context = Map.get(meta, :updog_context, %{})

        UpdogElixirClient.notify_error(:error, %RuntimeError{message: to_string(message)}, [],
          context: context
        )

      _ ->
        :ok
    end
  end

  def log(_event, _config), do: :ok

  @impl true
  def adding_handler(config), do: {:ok, config}

  @impl true
  def removing_handler(_config), do: :ok

  @impl true
  def changing_config(_action, _old_config, new_config), do: {:ok, new_config}
end
