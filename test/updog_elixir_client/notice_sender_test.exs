defmodule UpdogElixirClient.NoticeSenderTest do
  use ExUnit.Case

  import Mox

  alias UpdogElixirClient.NoticeSender

  setup :verify_on_exit!

  describe "send_notice/2" do
    test "sends notice payload via http_client" do
      expect(UpdogElixirClient.MockHttpClient, :post_json, fn url, payload ->
        assert url =~ "/api/v1/notices"
        assert payload.error_class == "RuntimeError"
        assert payload.message == "test error"
        :ok
      end)

      exception = %RuntimeError{message: "test error"}
      NoticeSender.send_notice(exception)
    end

    test "includes stacktrace in payload" do
      stacktrace = [
        {MyApp.Module, :function, 2, [file: ~c"lib/my_app.ex", line: 42]}
      ]

      expect(UpdogElixirClient.MockHttpClient, :post_json, fn _url, payload ->
        assert length(payload.stacktrace) == 1
        assert hd(payload.stacktrace)["file"] == "lib/my_app.ex"
        :ok
      end)

      exception = %RuntimeError{message: "test"}
      NoticeSender.send_notice(exception, stacktrace: stacktrace)
    end
  end

  describe "send_error/4" do
    test "sends error payload via http_client" do
      expect(UpdogElixirClient.MockHttpClient, :post_json, fn url, payload ->
        assert url =~ "/api/v1/notices"
        assert payload.error_class == "RuntimeError"
        assert payload.message == "boom"
        :ok
      end)

      NoticeSender.send_error(:error, %RuntimeError{message: "boom"}, [])
    end
  end
end
