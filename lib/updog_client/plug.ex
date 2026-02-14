defmodule UpdogClient.Plug do
  @moduledoc """
  Plug integration for auto-capturing HTTP errors.

  Add to your endpoint or router:

      use UpdogClient.Plug
  """

  defmacro __using__(_opts) do
    quote do
      @before_compile UpdogClient.Plug
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defoverridable call: 2

      def call(conn, opts) do
        try do
          super(conn, opts)
        rescue
          exception ->
            stacktrace = __STACKTRACE__

            request = %{
              method: conn.method,
              url: "#{conn.scheme}://#{conn.host}#{conn.request_path}",
              params: conn.params
            }

            UpdogClient.notify(exception, stacktrace: stacktrace, request: request)
            reraise exception, stacktrace
        end
      end
    end
  end
end
