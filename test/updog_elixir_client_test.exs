defmodule UpdogElixirClientTest do
  use ExUnit.Case

  import Mox

  setup :verify_on_exit!

  describe "enabled?/0" do
    test "returns true by default" do
      Application.delete_env(:updog_elixir_client, :enabled)
      assert UpdogElixirClient.enabled?() == true
    end

    test "returns false when configured" do
      Application.put_env(:updog_elixir_client, :enabled, false)
      assert UpdogElixirClient.enabled?() == false
    after
      Application.delete_env(:updog_elixir_client, :enabled)
    end
  end

  describe "notify/2" do
    test "sends notice when enabled" do
      Application.delete_env(:updog_elixir_client, :enabled)

      expect(UpdogElixirClient.MockHttpClient, :post_json, fn _url, _payload ->
        :ok
      end)

      exception = %RuntimeError{message: "test error"}
      assert :ok = UpdogElixirClient.notify(exception)
    end

    test "skips when disabled" do
      Application.put_env(:updog_elixir_client, :enabled, false)

      # No mock expectation = verify_on_exit! ensures no calls made
      exception = %RuntimeError{message: "test error"}
      assert :ok = UpdogElixirClient.notify(exception)
    after
      Application.delete_env(:updog_elixir_client, :enabled)
    end
  end

  describe "report_event/1" do
    test "pushes event when enabled" do
      Application.delete_env(:updog_elixir_client, :enabled)

      event = %{type: "test", data: "hello"}
      assert :ok = UpdogElixirClient.report_event(event)
    end

    test "skips when disabled" do
      Application.put_env(:updog_elixir_client, :enabled, false)

      event = %{type: "test", data: "hello"}
      assert :ok = UpdogElixirClient.report_event(event)
    after
      Application.delete_env(:updog_elixir_client, :enabled)
    end
  end
end
