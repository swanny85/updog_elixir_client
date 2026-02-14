defmodule UpdogElixirClient.Plug do
  @moduledoc """
  Plug integration for auto-capturing HTTP errors.

  Add to your router:

      use UpdogElixirClient.Plug
  """

  defmacro __using__(_opts) do
    quote do
      use Plug.ErrorHandler

      @impl Plug.ErrorHandler
      def handle_errors(conn, %{kind: _kind, reason: reason, stack: stacktrace}) do
        request = %{
          method: conn.method,
          url: "#{conn.scheme}://#{conn.host}#{conn.request_path}",
          params: conn.params
        }

        if is_exception(reason) do
          UpdogElixirClient.notify(reason, stacktrace: stacktrace, request: request)
        else
          UpdogElixirClient.notify_error(:error, reason, stacktrace, request: request)
        end
      end
    end
  end
end
