defmodule ScoreTracker.GameType.FiveCrownsTest do
  use ExUnit.Case, async: true

  alias ScoreTracker.GameType.FiveCrowns
  alias ScoreTracker.UpdateScore

  describe "allows_negative_scores?/0" do
    test "returns expected value" do
      refute FiveCrowns.allows_negative_scores?()
    end
  end

  describe "friendly_name/0" do
    test "returns expected value" do
      assert FiveCrowns.friendly_name() == "Five Crowns"
    end
  end

  describe "max_players/0" do
    test "returns expected value" do
      assert FiveCrowns.max_players() == 7
    end
  end

  describe "max_rounds/0" do
    test "returns expected value" do
      assert FiveCrowns.max_rounds() == 11
    end
  end

  describe "round_info/1" do
    test "returns expected value" do
      prefix = fn info -> "* Wild Cards: #{info}" end

      assert FiveCrowns.round_info(1) == [prefix.("3s and Jokers")]
      assert FiveCrowns.round_info(2) == [prefix.("4s and Jokers")]
      assert FiveCrowns.round_info(3) == [prefix.("5s and Jokers")]
      assert FiveCrowns.round_info(4) == [prefix.("6s and Jokers")]
      assert FiveCrowns.round_info(5) == [prefix.("7s and Jokers")]
      assert FiveCrowns.round_info(6) == [prefix.("8s and Jokers")]
      assert FiveCrowns.round_info(7) == [prefix.("9s and Jokers")]
      assert FiveCrowns.round_info(8) == [prefix.("10s and Jokers")]
      assert FiveCrowns.round_info(9) == [prefix.("Jacks and Jokers")]
      assert FiveCrowns.round_info(10) == [prefix.("Queens and Jokers")]
      assert FiveCrowns.round_info(11) == [prefix.("Kings and Jokers")]
    end
  end

  describe "validate_round_score/2" do
    test "valid params" do
      result =
        %UpdateScore{}
        |> Ecto.Changeset.cast(%{"score" => 10}, [:score])
        |> FiveCrowns.validate_round_score(:score)
        |> Ecto.Changeset.apply_action(:update)

      assert {:ok, %UpdateScore{score: 10}} == result
    end

    test "invalid min score" do
      changeset =
        %UpdateScore{}
        |> Ecto.Changeset.cast(%{"score" => -100}, [:score])
        |> FiveCrowns.validate_round_score(:score)

      assert %{score: ["must be greater than or equal to 0"]} ==
               ScoreTracker.Changeset.format_errors(changeset)
    end

    test "invalid max score" do
      changeset =
        %UpdateScore{}
        |> Ecto.Changeset.cast(%{"score" => 200}, [:score])
        |> FiveCrowns.validate_round_score(:score)

      assert %{score: ["must be less than or equal to 127"]} ==
               ScoreTracker.Changeset.format_errors(changeset)
    end

    test "invalid type" do
      changeset =
        %UpdateScore{}
        |> Ecto.Changeset.cast(%{"score" => "four"}, [:score])
        |> FiveCrowns.validate_round_score(:score)

      assert %{score: ["must be of type: integer"]} ==
               ScoreTracker.Changeset.format_errors(changeset)
    end
  end

  describe "winning_score_type/0" do
    test "returns expected value" do
      assert FiveCrowns.winning_score_type() == :lowest
    end
  end
end
