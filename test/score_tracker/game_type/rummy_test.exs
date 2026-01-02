defmodule ScoreTracker.GameType.RummyTest do
  use ExUnit.Case, async: true

  alias ScoreTracker.GameType.Rummy
  alias ScoreTracker.UpdateScore

  describe "allows_negative_scores?/0" do
    test "returns expected value" do
      refute Rummy.allows_negative_scores?()
    end
  end

  describe "friendly_name/0" do
    test "returns expected value" do
      assert Rummy.friendly_name() == "Rummy"
    end
  end

  describe "max_players/0" do
    test "returns expected value" do
      assert Rummy.max_players() == 8
    end
  end

  describe "max_rounds/0" do
    test "returns expected value" do
      assert Rummy.max_rounds() == 8
    end
  end

  describe "round_info/1" do
    test "returns expected value" do
      prefix = fn info -> "* Objective: #{info}" end
      wilds = "* Wild Cards: 2s and Jokers"

      assert Rummy.round_info(1) == [prefix.("2 three of a kinds"), wilds]
      assert Rummy.round_info(2) == [prefix.("1 three of a kind and 1 four card run"), wilds]
      assert Rummy.round_info(3) == [prefix.("2 four card runs"), wilds]
      assert Rummy.round_info(4) == [prefix.("3 three of a kinds"), wilds]
      assert Rummy.round_info(5) == [prefix.("2 three of a kinds and 1 four card run"), wilds]
      assert Rummy.round_info(6) == [prefix.("1 three of a kind and 2 four card runs"), wilds]
      assert Rummy.round_info(7) == [prefix.("3 four card runs"), wilds]
      assert Rummy.round_info(8) == [prefix.("4 three of a kinds"), wilds]
    end
  end

  describe "validate_round_score/2" do
    test "valid params" do
      result =
        %UpdateScore{}
        |> Ecto.Changeset.cast(%{"score" => 10}, [:score])
        |> Rummy.validate_round_score(:score)
        |> Ecto.Changeset.apply_action(:update)

      assert {:ok, %UpdateScore{score: 10}} == result
    end

    test "invalid min score" do
      changeset =
        %UpdateScore{}
        |> Ecto.Changeset.cast(%{"score" => -100}, [:score])
        |> Rummy.validate_round_score(:score)

      assert %{score: ["must be greater than or equal to 0"]} ==
               ScoreTracker.Changeset.format_errors(changeset)
    end

    test "invalid max score" do
      changeset =
        %UpdateScore{}
        |> Ecto.Changeset.cast(%{"score" => 1100}, [:score])
        |> Rummy.validate_round_score(:score)

      assert %{score: ["must be less than or equal to 1000"]} ==
               ScoreTracker.Changeset.format_errors(changeset)
    end

    test "invalid type" do
      changeset =
        %UpdateScore{}
        |> Ecto.Changeset.cast(%{"score" => "four"}, [:score])
        |> Rummy.validate_round_score(:score)

      assert %{score: ["must be of type: integer"]} ==
               ScoreTracker.Changeset.format_errors(changeset)
    end
  end

  describe "winning_score_type/0" do
    test "returns expected value" do
      assert Rummy.winning_score_type() == :lowest
    end
  end
end
