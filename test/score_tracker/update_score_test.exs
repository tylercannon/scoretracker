defmodule ScoreTracker.UpdateScoreTest do
  use ExUnit.Case, async: true

  alias ScoreTracker.UpdateScore

  describe "changeset/3" do
    test "valid params for ripple" do
      changeset = UpdateScore.changeset(%UpdateScore{}, :ripple, %{"score" => 10})

      assert changeset.valid?
      assert {:ok, %UpdateScore{score: 10}} == Ecto.Changeset.apply_action(changeset, :update)
    end

    test "valid params for rummy" do
      changeset = UpdateScore.changeset(%UpdateScore{}, :rummy, %{"score" => 0})

      assert changeset.valid?
      assert {:ok, %UpdateScore{score: 0}} == Ecto.Changeset.apply_action(changeset, :update)
    end

    test "valid params for custom game" do
      changeset = UpdateScore.changeset(%UpdateScore{}, :custom, %{"score" => 17})

      assert changeset.valid?
      assert {:ok, %UpdateScore{score: 17}} == Ecto.Changeset.apply_action(changeset, :update)
    end

    test "empty params" do
      changeset = UpdateScore.changeset(%UpdateScore{}, :custom, %{})

      refute changeset.valid?

      assert %{score: ["can't be blank"]} == ScoreTracker.Changeset.format_errors(changeset)
    end

    test "invalid params for ripple" do
      changeset = UpdateScore.changeset(%UpdateScore{}, :ripple, %{"score" => -100})

      refute changeset.valid?

      assert %{score: ["must be greater than or equal to -50"]} ==
               ScoreTracker.Changeset.format_errors(changeset)
    end

    test "invalid params for rummy" do
      changeset = UpdateScore.changeset(%UpdateScore{}, :rummy, %{"score" => 12})

      refute changeset.valid?

      assert %{score: ["must be a multiple of 5"]} ==
               ScoreTracker.Changeset.format_errors(changeset)
    end

    test "invalid params for custom game" do
      changeset = UpdateScore.changeset(%UpdateScore{}, :custom, %{"score" => true})

      refute changeset.valid?

      assert %{score: ["must be of type: integer"]} ==
               ScoreTracker.Changeset.format_errors(changeset)
    end
  end
end
