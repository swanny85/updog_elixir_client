defmodule UpdogElixirClient.HttpClient do
  @moduledoc """
  Behaviour for HTTP client used by the Updog APM client.
  """

  @callback post(String.t(), String.t()) :: :ok | {:error, term()}
  @callback post_json(String.t(), map()) :: :ok | {:error, term()}
end
