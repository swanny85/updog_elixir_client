defmodule UpdogElixirClient.ContextTest do
  use ExUnit.Case

  alias UpdogElixirClient.Context

  setup do
    Context.clear()
    :ok
  end

  describe "set/1 and get/0" do
    test "sets and retrieves context" do
      Context.set(%{user_id: 123})
      assert %{user_id: 123} = Context.get()
    end

    test "merges new context with existing" do
      Context.set(%{user_id: 123})
      Context.set(%{request_id: "abc"})
      ctx = Context.get()
      assert ctx.user_id == 123
      assert ctx.request_id == "abc"
    end

    test "overwrites existing keys on merge" do
      Context.set(%{user_id: 123})
      Context.set(%{user_id: 456})
      assert %{user_id: 456} = Context.get()
    end
  end

  describe "clear/0" do
    test "clears all context" do
      Context.set(%{user_id: 123, role: "admin"})
      Context.clear()
      assert Context.get() == %{}
    end
  end

  describe "get/0" do
    test "returns empty map when no context set" do
      assert Context.get() == %{}
    end
  end

  describe "process isolation" do
    test "context is isolated between processes" do
      Context.set(%{user_id: 123})

      task =
        Task.async(fn ->
          assert Context.get() == %{}
          Context.set(%{user_id: 456})
          Context.get()
        end)

      other_ctx = Task.await(task)
      assert other_ctx == %{user_id: 456}
      assert Context.get() == %{user_id: 123}
    end
  end
end
