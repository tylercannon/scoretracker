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

  describe "score_types/0" do
    test "returns expected value" do
      assert GameType.score_types() == [:highest, :lowest]
    end
  end

  describe "allows_negative_scores?/1" do
    test "returns expected value" do
      assert GameType.allows_negative_scores?(:ripple)
      refute GameType.allows_negative_scores?(:rummy)
      assert GameType.allows_negative_scores?(:custom)
    end
  end

  describe "friendly_name/2" do
    test "returns expected value" do
      assert GameType.friendly_name(:ripple, nil) == "Ripple"
      assert GameType.friendly_name(:ripple, "MyGame") == "Ripple"

      assert GameType.friendly_name(:rummy, nil) == "Rummy"
      assert GameType.friendly_name(:rummy, "MyGame") == "Rummy"

      assert GameType.friendly_name(:custom, nil) == "Custom Game"
      assert GameType.friendly_name(:custom, "MyGame") == "MyGame"
    end
  end

  describe "friendly_name/1" do
    test "returns expected value" do
      assert GameType.friendly_name(:ripple) == "Ripple"
      assert GameType.friendly_name(:rummy) == "Rummy"
      assert GameType.friendly_name(:custom) == "Custom Game"
    end
  end

  describe "friendly_score_type/1" do
    test "returns the expected value" do
      assert GameType.friendly_score_type(:highest) == "Highest Score"
      assert GameType.friendly_score_type(:lowest) == "Lowest Score"
    end
  end

  describe "round_info/2" do
    test "returns expected type" do
      assert is_list(GameType.round_info(:ripple, 1))
      assert is_list(GameType.round_info(:rummy, 1))
      assert is_nil(GameType.round_info(:custom, 1))
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
               type: :rummy,
               max_players: 8,
               max_rounds: 8,
               winning_score_type: :lowest
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
