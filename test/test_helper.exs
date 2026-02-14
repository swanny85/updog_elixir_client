ExUnit.start()
Mox.defmock(UpdogElixirClient.MockHttpClient, for: UpdogElixirClient.HttpClient)
Application.put_env(:updog_elixir_client, :http_client, UpdogElixirClient.MockHttpClient)
