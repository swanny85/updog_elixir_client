defmodule UpdogElixirClient.BacktraceTest do
  use ExUnit.Case

  alias UpdogElixirClient.Backtrace

  describe "format/1" do
    test "formats standard stacktrace entry" do
      stacktrace = [
        {MyApp.Module, :function, 2, [file: ~c"lib/my_app/module.ex", line: 42]}
      ]

      assert [entry] = Backtrace.format(stacktrace)
      assert entry["file"] == "lib/my_app/module.ex"
      assert entry["line"] == 42
      assert entry["function"] == "MyApp.Module.function/2"
      assert entry["module"] == "MyApp.Module"
    end

    test "handles entry without file info" do
      stacktrace = [
        {MyApp.Module, :function, 2, [line: 10]}
      ]

      assert [entry] = Backtrace.format(stacktrace)
      assert entry["file"] == "nofile"
      assert entry["line"] == 10
    end

    test "handles entry without line info" do
      stacktrace = [
        {MyApp.Module, :function, 2, [file: ~c"lib/my_app.ex"]}
      ]

      assert [entry] = Backtrace.format(stacktrace)
      assert entry["line"] == 0
      assert entry["file"] == "lib/my_app.ex"
    end

    test "handles entry with no file or line" do
      stacktrace = [
        {MyApp.Module, :function, 2, []}
      ]

      assert [entry] = Backtrace.format(stacktrace)
      assert entry["file"] == "nofile"
      assert entry["line"] == 0
    end

    test "handles empty stacktrace" do
      assert Backtrace.format([]) == []
    end

    test "handles non-list input" do
      assert Backtrace.format(nil) == []
      assert Backtrace.format("not a list") == []
    end

    test "handles function with arity as list (args)" do
      stacktrace = [
        {MyApp.Module, :function, [:arg1, :arg2, :arg3], [file: ~c"lib/my_app.ex", line: 1]}
      ]

      assert [entry] = Backtrace.format(stacktrace)
      assert entry["function"] == "MyApp.Module.function/3"
    end

    test "handles malformed stacktrace entry" do
      stacktrace = [:not_a_tuple]

      assert [entry] = Backtrace.format(stacktrace)
      assert entry["file"] == "?"
      assert entry["line"] == 0
      assert entry["function"] == "?"
      assert entry["module"] == "?"
    end

    test "formats multiple entries" do
      stacktrace = [
        {MyApp.A, :foo, 1, [file: ~c"lib/a.ex", line: 10]},
        {MyApp.B, :bar, 2, [file: ~c"lib/b.ex", line: 20]}
      ]

      result = Backtrace.format(stacktrace)
      assert length(result) == 2
      assert Enum.at(result, 0)["module"] == "MyApp.A"
      assert Enum.at(result, 1)["module"] == "MyApp.B"
    end
  end
end
