defmodule ScoreTracker.GameTypeTest do
  use ExUnit.Case, async: true

  alias ScoreTracker.GameType

  describe "built_in_types/0" do
    test "returns expected value" do
      assert GameType.built_in_types() == [:ripple, :rummy]
    end
  end

  describe "game_types/0" do
    test "returns expected value" do
      assert GameType.game_types() == [:ripple, :rummy, :custom]
    end
  end

  describe "friendly_name/1" do
    test "returns expected value" do
      assert GameType.friendly_name(:ripple) == "Ripple"
      assert GameType.friendly_name(:rummy) == "Rummy"
      assert GameType.friendly_name(:custom) == "Custom Game"
    end
  end

  describe "built_in?/1" do
    test "returns expected value" do
      assert GameType.built_in?(:ripple)
      assert GameType.built_in?(:rummy)
      refute GameType.built_in?(:custom)
    end
  end

  describe "default_game/0" do
    test "returns expected value" do
      assert GameType.default_game() == %{
               type: :ripple,
               max_players: 6,
               max_rounds: 10
             }
    end
  end

  describe "impl/1" do
    test "returns expected value" do
      assert GameType.impl(:ripple) == GameType.Ripple
      assert GameType.impl(:rummy) == GameType.Rummy
    end
  end
end
