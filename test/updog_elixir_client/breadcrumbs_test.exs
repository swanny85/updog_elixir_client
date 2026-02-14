defmodule UpdogElixirClient.BreadcrumbsTest do
  use ExUnit.Case

  alias UpdogElixirClient.Breadcrumbs

  setup do
    Breadcrumbs.clear()
    :ok
  end

  describe "add/2 and get/0" do
    test "adds and retrieves breadcrumbs" do
      Breadcrumbs.add("clicked button", %{id: "submit"})
      crumbs = Breadcrumbs.get()
      assert length(crumbs) == 1
      assert hd(crumbs).message == "clicked button"
      assert hd(crumbs).metadata == %{id: "submit"}
    end

    test "includes timestamp" do
      Breadcrumbs.add("test action")
      [crumb] = Breadcrumbs.get()
      assert is_binary(crumb.timestamp)
    end

    test "maintains chronological order (oldest first)" do
      Breadcrumbs.add("first")
      Breadcrumbs.add("second")
      Breadcrumbs.add("third")
      crumbs = Breadcrumbs.get()
      messages = Enum.map(crumbs, & &1.message)
      assert messages == ["first", "second", "third"]
    end
  end

  describe "max breadcrumbs limit" do
    test "limits to 40 breadcrumbs" do
      for i <- 1..50 do
        Breadcrumbs.add("crumb #{i}")
      end

      crumbs = Breadcrumbs.get()
      assert length(crumbs) == 40
    end

    test "keeps most recent breadcrumbs when limit exceeded" do
      for i <- 1..45 do
        Breadcrumbs.add("crumb #{i}")
      end

      crumbs = Breadcrumbs.get()
      # The newest ones should be kept
      last = List.last(crumbs)
      assert last.message == "crumb 45"
    end
  end

  describe "clear/0" do
    test "clears all breadcrumbs" do
      Breadcrumbs.add("test")
      Breadcrumbs.add("test2")
      Breadcrumbs.clear()
      assert Breadcrumbs.get() == []
    end
  end

  describe "get/0" do
    test "returns empty list when no breadcrumbs" do
      assert Breadcrumbs.get() == []
    end
  end
end
