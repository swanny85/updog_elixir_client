defmodule UpdogElixirClient.Backtrace do
  @moduledoc """
  Formats Erlang stacktraces into structured data for the Updog API.
  """

  def format(stacktrace) when is_list(stacktrace) do
    Enum.map(stacktrace, &format_entry/1)
  end

  def format(_), do: []

  defp format_entry({module, function, arity, location}) do
    %{
      "file" => format_file(location),
      "line" => Keyword.get(location, :line, 0),
      "function" => "#{inspect(module)}.#{function}/#{normalize_arity(arity)}",
      "module" => inspect(module)
    }
  end

  defp format_entry(_), do: %{"file" => "?", "line" => 0, "function" => "?", "module" => "?"}

  defp format_file(location) do
    case Keyword.get(location, :file) do
      nil -> "nofile"
      file -> to_string(file)
    end
  end

  defp normalize_arity(arity) when is_integer(arity), do: arity
  defp normalize_arity(args) when is_list(args), do: length(args)
  defp normalize_arity(_), do: 0
end
