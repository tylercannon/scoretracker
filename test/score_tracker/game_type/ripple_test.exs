defmodule ScoreTracker.GameType.RippleTest do
  use ExUnit.Case, async: true

  alias ScoreTracker.GameType.Ripple
  alias ScoreTracker.UpdateScore

  describe "allows_negative_scores?/0" do
    test "returns expected value" do
      assert Ripple.allows_negative_scores?()
    end
  end

  describe "friendly_name/0" do
    test "returns expected value" do
      assert Ripple.friendly_name() == "Ripple"
    end
  end

  describe "max_players/0" do
    test "returns expected value" do
      assert Ripple.max_players() == 6
    end
  end

  describe "max_rounds/0" do
    test "returns expected value" do
      assert Ripple.max_rounds() == 10
    end
  end

  describe "validate_round_score/2" do
    test "valid params" do
      result =
        %UpdateScore{}
        |> Ecto.Changeset.cast(%{"score" => 10}, [:score])
        |> Ripple.validate_round_score(:score)
        |> Ecto.Changeset.apply_action(:update)

      assert {:ok, %UpdateScore{score: 10}} == result
    end

    test "invalid min score" do
      changeset =
        %UpdateScore{}
        |> Ecto.Changeset.cast(%{"score" => -100}, [:score])
        |> Ripple.validate_round_score(:score)

      assert %{score: ["must be greater than or equal to -50"]} ==
               ScoreTracker.Changeset.format_errors(changeset)
    end

    test "invalid max score" do
      changeset =
        %UpdateScore{}
        |> Ecto.Changeset.cast(%{"score" => 150}, [:score])
        |> Ripple.validate_round_score(:score)

      assert %{score: ["must be less than or equal to 145"]} ==
               ScoreTracker.Changeset.format_errors(changeset)
    end

    test "invalid type" do
      changeset =
        %UpdateScore{}
        |> Ecto.Changeset.cast(%{"score" => "four"}, [:score])
        |> Ripple.validate_round_score(:score)

      assert %{score: ["must be of type: integer"]} ==
               ScoreTracker.Changeset.format_errors(changeset)
    end
  end
end
