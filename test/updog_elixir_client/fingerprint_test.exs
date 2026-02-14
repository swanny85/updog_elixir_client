defmodule UpdogElixirClient.FingerprintTest do
  use ExUnit.Case

  alias UpdogElixirClient.Fingerprint

  describe "generate/2" do
    test "produces deterministic output for same input" do
      frames = [
        %{"file" => "lib/my_app.ex", "function" => "MyApp.run/0"},
        %{"file" => "lib/my_app.ex", "function" => "MyApp.start/1"}
      ]

      result1 = Fingerprint.generate("RuntimeError", frames)
      result2 = Fingerprint.generate("RuntimeError", frames)
      assert result1 == result2
    end

    test "produces different output for different error classes" do
      frames = [
        %{"file" => "lib/my_app.ex", "function" => "MyApp.run/0"}
      ]

      result1 = Fingerprint.generate("RuntimeError", frames)
      result2 = Fingerprint.generate("ArgumentError", frames)
      assert result1 != result2
    end

    test "produces different output for different stacktraces" do
      frames1 = [%{"file" => "lib/a.ex", "function" => "A.run/0"}]
      frames2 = [%{"file" => "lib/b.ex", "function" => "B.run/0"}]

      result1 = Fingerprint.generate("RuntimeError", frames1)
      result2 = Fingerprint.generate("RuntimeError", frames2)
      assert result1 != result2
    end

    test "only uses first 5 frames" do
      frames = for i <- 1..10, do: %{"file" => "lib/#{i}.ex", "function" => "M.f/#{i}"}

      result_10 = Fingerprint.generate("RuntimeError", frames)
      result_5 = Fingerprint.generate("RuntimeError", Enum.take(frames, 5))
      assert result_10 == result_5
    end

    test "handles empty stacktrace" do
      result = Fingerprint.generate("RuntimeError", [])
      assert is_binary(result)
      assert byte_size(result) > 0
    end

    test "handles frames with missing keys" do
      frames = [%{}, %{"file" => "lib/a.ex"}]

      result = Fingerprint.generate("RuntimeError", frames)
      assert is_binary(result)
    end
  end
end
