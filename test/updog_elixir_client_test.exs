defmodule UpdogElixirClientTest do
  use ExUnit.Case

  import Mox

  setup :verify_on_exit!

  setup do
    original_key = Application.get_env(:updog_elixir_client, :api_key)

    on_exit(fn ->
      if original_key do
        Application.put_env(:updog_elixir_client, :api_key, original_key)
      else
        Application.delete_env(:updog_elixir_client, :api_key)
      end
    end)

    :ok
  end

  describe "enabled?/0" do
    test "returns true when api_key is set" do
      Application.put_env(:updog_elixir_client, :api_key, "test-key")
      assert UpdogElixirClient.enabled?() == true
    end

    test "returns false when no api_key" do
      Application.delete_env(:updog_elixir_client, :api_key)
      assert UpdogElixirClient.enabled?() == false
    end
  end

  describe "notify/2" do
    test "sends notice when api_key is set" do
      Application.put_env(:updog_elixir_client, :api_key, "test-key")

      expect(UpdogElixirClient.MockHttpClient, :post_json, fn _url, _payload ->
        :ok
      end)

      exception = %RuntimeError{message: "test error"}
      assert :ok = UpdogElixirClient.notify(exception)
    end

    test "skips when no api_key" do
      Application.delete_env(:updog_elixir_client, :api_key)

      # No mock expectation = verify_on_exit! ensures no calls made
      exception = %RuntimeError{message: "test error"}
      assert :ok = UpdogElixirClient.notify(exception)
    end
  end

  describe "report_event/1" do
    test "pushes event when api_key is set" do
      Application.put_env(:updog_elixir_client, :api_key, "test-key")

      event = %{type: "test", data: "hello"}
      assert :ok = UpdogElixirClient.report_event(event)
    end

    test "skips when no api_key" do
      Application.delete_env(:updog_elixir_client, :api_key)

      event = %{type: "test", data: "hello"}
      assert :ok = UpdogElixirClient.report_event(event)
    end
  end
end
