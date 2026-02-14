defmodule UpdogElixirClient.Fingerprint do
  @moduledoc """
  Generates SHA256 fingerprints matching the server-side algorithm.
  """

  def generate(error_class, stacktrace) when is_list(stacktrace) do
    frames =
      stacktrace
      |> Enum.take(5)
      |> Enum.map(fn frame ->
        file = Map.get(frame, "file", "")
        function = Map.get(frame, "function", "")
        "#{file}:#{function}"
      end)
      |> Enum.join("|")

    :crypto.hash(:sha256, "#{error_class}|#{frames}")
    |> Base.hex_encode32(case: :lower, padding: false)
  end
end
