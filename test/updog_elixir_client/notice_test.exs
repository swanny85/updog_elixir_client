defmodule UpdogElixirClient.NoticeTest do
  use ExUnit.Case

  alias UpdogElixirClient.{Notice, Context, Breadcrumbs}

  setup do
    Context.clear()
    Breadcrumbs.clear()
    :ok
  end

  describe "build/2" do
    test "builds notice from exception" do
      exception = %RuntimeError{message: "something went wrong"}
      notice = Notice.build(exception)

      assert notice.error_class == "RuntimeError"
      assert notice.message == "something went wrong"
      assert is_binary(notice.hostname)
      assert notice.environment == "dev"
      assert notice.stacktrace == []
      assert notice.context == %{}
      assert notice.breadcrumbs == []
    end

    test "includes stacktrace when provided" do
      exception = %RuntimeError{message: "test"}

      stacktrace = [
        {MyApp.Module, :function, 2, [file: ~c"lib/my_app.ex", line: 42]}
      ]

      notice = Notice.build(exception, stacktrace: stacktrace)
      assert length(notice.stacktrace) == 1
      assert hd(notice.stacktrace)["file"] == "lib/my_app.ex"
    end

    test "includes context" do
      Context.set(%{user_id: 123})
      exception = %RuntimeError{message: "test"}
      notice = Notice.build(exception)

      assert notice.context == %{user_id: 123}
    end

    test "includes breadcrumbs" do
      Breadcrumbs.add("clicked button")
      exception = %RuntimeError{message: "test"}
      notice = Notice.build(exception)

      assert length(notice.breadcrumbs) == 1
      assert hd(notice.breadcrumbs).message == "clicked button"
    end

    test "includes request data when provided" do
      exception = %RuntimeError{message: "test"}
      request = %{method: "GET", url: "/test"}
      notice = Notice.build(exception, request: request)

      assert notice.request == %{method: "GET", url: "/test"}
    end

    test "defaults request to empty map" do
      exception = %RuntimeError{message: "test"}
      notice = Notice.build(exception)

      assert notice.request == %{}
    end
  end

  describe "build_from_error/4" do
    test "builds notice from kind/reason/stacktrace" do
      stacktrace = [
        {MyApp.Module, :function, 2, [file: ~c"lib/my_app.ex", line: 10]}
      ]

      notice = Notice.build_from_error(:error, %RuntimeError{message: "boom"}, stacktrace)

      assert notice.error_class == "RuntimeError"
      assert notice.message == "boom"
      assert length(notice.stacktrace) == 1
    end

    test "formats error class for :error kind with exception" do
      notice =
        Notice.build_from_error(:error, %ArgumentError{message: "bad arg"}, [])

      assert notice.error_class == "ArgumentError"
    end

    test "formats error class for :error kind with non-exception" do
      notice = Notice.build_from_error(:error, :badarg, [])

      assert notice.error_class == ":badarg"
    end

    test "formats error class for :throw kind" do
      notice = Notice.build_from_error(:throw, :some_value, [])

      assert notice.error_class == "throw"
    end

    test "formats error class for :exit kind" do
      notice = Notice.build_from_error(:exit, :normal, [])

      assert notice.error_class == "exit"
    end

    test "formats message for exception reason" do
      notice =
        Notice.build_from_error(:error, %RuntimeError{message: "test msg"}, [])

      assert notice.message == "test msg"
    end

    test "formats message for non-exception reason" do
      notice = Notice.build_from_error(:throw, {:bad_value, 42}, [])

      assert notice.message == "{:bad_value, 42}"
    end
  end
end
