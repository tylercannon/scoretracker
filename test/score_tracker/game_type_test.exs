defmodule ScoreTracker.GameTypeTest do
  use ExUnit.Case, async: true

  alias ScoreTracker.GameType

  describe "built_in?/1" do
    test "returns expected value" do
      assert GameType.built_in?(:ripple)
      assert GameType.built_in?(:rummy)
      refute GameType.built_in?(:custom)
    end
  end

  describe "impl/1" do
    test "returns expected value" do
      assert GameType.impl(:ripple) == GameType.Ripple
      assert GameType.impl(:rummy) == GameType.Rummy
    end
  end
end
