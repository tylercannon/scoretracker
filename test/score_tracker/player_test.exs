defmodule ScoreTracker.PlayerTest do
  use ExUnit.Case, async: true

  alias ScoreTracker.Player

  describe "changeset/2" do
    test "valid params" do
      changeset = Player.changeset(%Player{}, %{"name" => "Test"})

      assert changeset.valid?
      assert {:ok, %Player{name: "Test"}} == Ecto.Changeset.apply_action(changeset, :update)
    end

    test "empty params" do
      changeset = Player.changeset(%Player{}, %{})

      refute changeset.valid?

      assert %{name: ["can't be blank"]} == ScoreTracker.Changeset.format_errors(changeset)
    end

    test "invalid params" do
      changeset = Player.changeset(%Player{}, %{"name" => "ALongNameWithAnInvalidFormat1"})

      refute changeset.valid?

      assert %{
               name: ["must be valid format", "should be at most 12 character(s)"]
             } == ScoreTracker.Changeset.format_errors(changeset)
    end
  end
end
