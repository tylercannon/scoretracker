defmodule ScoreTracker.JoinGameTest do
  use ExUnit.Case, async: true

  alias ScoreTracker.JoinGame

  describe "valid_game_id?/1" do
    test "returns the expected value" do
      assert JoinGame.valid_game_id?("ABC12345")
      assert JoinGame.valid_game_id?("12345678")
      assert JoinGame.valid_game_id?("ABCDEFGH")

      refute JoinGame.valid_game_id?(nil)
      refute JoinGame.valid_game_id?("")
      refute JoinGame.valid_game_id?("ABC1234")
      refute JoinGame.valid_game_id?("ABC123456")
      refute JoinGame.valid_game_id?("ABC1234!")
    end
  end

  describe "changeset/2" do
    test "valid params" do
      params = %{"player_name" => "Example", "game_id" => "ABC12345"}
      changeset = JoinGame.changeset(%JoinGame{}, params)

      assert changeset.valid?

      assert {:ok, %JoinGame{player_name: "Example", game_id: "ABC12345"}} ==
               Ecto.Changeset.apply_action(changeset, :update)
    end

    test "upcases game id" do
      params = %{"player_name" => "Example", "game_id" => "abc12345"}
      changeset = JoinGame.changeset(%JoinGame{}, params)

      assert changeset.valid?

      assert {:ok, %JoinGame{player_name: "Example", game_id: "ABC12345"}} ==
               Ecto.Changeset.apply_action(changeset, :update)
    end

    test "empty params" do
      changeset = JoinGame.changeset(%JoinGame{}, %{})

      refute changeset.valid?

      assert %{
               player_name: ["can't be blank"],
               game_id: ["can't be blank"]
             } == ScoreTracker.Changeset.format_errors(changeset)
    end

    test "invalid params" do
      params = %{"player_name" => "Example123", "game_id" => "bad!"}
      changeset = JoinGame.changeset(%JoinGame{}, params)

      refute changeset.valid?

      assert %{
               player_name: ["must be valid format"],
               game_id: ["must be valid format", "should be 8 character(s)"]
             } == ScoreTracker.Changeset.format_errors(changeset)
    end
  end

  describe "update/2" do
    test "valid params" do
      params = %{"player_name" => "Example", "game_id" => "abc12345"}

      assert {:ok, %JoinGame{player_name: "Example", game_id: "ABC12345"}} ==
               JoinGame.update(%JoinGame{}, params)
    end

    test "invalid params" do
      params = %{"player_name" => "", "game_id" => "bad!"}

      {:error, changeset} = JoinGame.update(%JoinGame{}, params)

      assert %{
               player_name: ["can't be blank"],
               game_id: ["must be valid format", "should be 8 character(s)"]
             } == ScoreTracker.Changeset.format_errors(changeset)
    end
  end
end
