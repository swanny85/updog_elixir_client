defmodule UpdogClientTest do
  use ExUnit.Case

  test "context set and get" do
    UpdogClient.context(%{user_id: 123})
    assert %{user_id: 123} = UpdogClient.Context.get()
  end

  test "breadcrumbs add and get" do
    UpdogClient.add_breadcrumb("clicked button", %{id: "submit"})
    crumbs = UpdogClient.Breadcrumbs.get()
    assert length(crumbs) >= 1
    assert hd(crumbs).message == "clicked button"
  end

  test "backtrace formatting" do
    stacktrace = [
      {MyApp.Module, :function, 2, [file: ~c"lib/my_app/module.ex", line: 42]}
    ]

    formatted = UpdogClient.Backtrace.format(stacktrace)
    assert [%{"file" => "lib/my_app/module.ex", "line" => 42} | _] = formatted
  end
end
