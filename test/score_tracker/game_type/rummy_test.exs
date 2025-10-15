defmodule ScoreTracker.GameType.RummyTest do
  use ExUnit.Case, async: true

  alias ScoreTracker.GameType.Rummy
  alias ScoreTracker.UpdateScore

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
end
