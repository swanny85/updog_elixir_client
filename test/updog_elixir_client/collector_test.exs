defmodule UpdogElixirClient.CollectorTest do
  use ExUnit.Case

  import Mox

  setup :verify_on_exit!

  setup do
    Mox.set_mox_global()

    :sys.replace_state(UpdogElixirClient.Collector, fn _state ->
      %{events: [], logs: [], metrics: []}
    end)

    :ok
  end

  describe "push_event/1" do
    test "accumulates events in state" do
      UpdogElixirClient.Collector.push_event(%{type: "test", data: 1})
      UpdogElixirClient.Collector.push_event(%{type: "test", data: 2})

      Process.sleep(50)

      state = :sys.get_state(UpdogElixirClient.Collector)
      assert length(state.events) == 2
    end
  end

  describe "flush" do
    test "timer-based flush sends accumulated events" do
      expect(UpdogElixirClient.MockHttpClient, :post_json, fn url, payload ->
        assert url =~ "/api/v1/events"
        assert length(payload.events) == 2
        :ok
      end)

      UpdogElixirClient.Collector.push_event(%{type: "test", data: 1})
      UpdogElixirClient.Collector.push_event(%{type: "test", data: 2})

      Process.sleep(50)
      send(Process.whereis(UpdogElixirClient.Collector), :flush)
      Process.sleep(50)
    end

    test "flush preserves event order" do
      expect(UpdogElixirClient.MockHttpClient, :post_json, fn _url, payload ->
        events = payload.events
        assert Enum.at(events, 0).data == 1
        assert Enum.at(events, 1).data == 2
        :ok
      end)

      UpdogElixirClient.Collector.push_event(%{type: "test", data: 1})
      UpdogElixirClient.Collector.push_event(%{type: "test", data: 2})

      Process.sleep(50)
      send(Process.whereis(UpdogElixirClient.Collector), :flush)
      Process.sleep(50)
    end

    test "flush does not send when empty" do
      send(Process.whereis(UpdogElixirClient.Collector), :flush)
      Process.sleep(50)
    end

    test "flush clears state after sending" do
      expect(UpdogElixirClient.MockHttpClient, :post_json, fn _url, _payload ->
        :ok
      end)

      UpdogElixirClient.Collector.push_event(%{type: "test"})
      Process.sleep(50)
      send(Process.whereis(UpdogElixirClient.Collector), :flush)
      Process.sleep(50)

      state = :sys.get_state(UpdogElixirClient.Collector)
      assert state.events == []
    end
  end

  describe "max batch size" do
    test "triggers immediate flush at 100 events" do
      expect(UpdogElixirClient.MockHttpClient, :post_json, fn url, payload ->
        assert url =~ "/api/v1/events"
        assert length(payload.events) == 100
        :ok
      end)

      for i <- 1..100 do
        UpdogElixirClient.Collector.push_event(%{type: "test", data: i})
      end

      Process.sleep(100)

      state = :sys.get_state(UpdogElixirClient.Collector)
      assert state.events == []
    end
  end
end
