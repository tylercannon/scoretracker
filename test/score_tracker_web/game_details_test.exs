defmodule ScoreTrackerWeb.GameDetailsTest do
  use ExUnit.Case, async: true

  alias ScoreTracker.{Game, Player}
  alias ScoreTrackerWeb.GameDetails

  describe "topic/1" do
    test "returns the expected value" do
      assert GameDetails.topic("abc") == "game:#abc"
    end
  end

  describe "in_progress?/1" do
    setup do
      game =
        Game.new(
          allow_spectators: true,
          host_id: "game-host",
          host_name: "Example",
          game_mode: :party,
          game_type: :custom,
          max_players: 4,
          max_rounds: 1,
          winning_score_type: :lowest
        )

      %{game: game}
    end

    test "returns the expected value when game isn't started", %{game: game} do
      refute GameDetails.in_progress?(game)
    end

    test "returns the expected value when game is in progress", %{game: game} do
      {:ok, game} = Game.start(game)

      assert GameDetails.in_progress?(game)
    end

    test "returns the expected value when game is complete", %{game: game} do
      {:ok, game} = Game.start(game)
      game = Game.advance_round(game)

      refute GameDetails.in_progress?(game)
    end
  end

  describe "complete?/1" do
    setup do
      game =
        Game.new(
          allow_spectators: true,
          host_id: "game-host",
          host_name: "Example",
          game_mode: :party,
          game_type: :custom,
          max_players: 4,
          max_rounds: 1,
          winning_score_type: :lowest
        )

      %{game: game}
    end

    test "returns the expected value when game isn't started", %{game: game} do
      refute GameDetails.complete?(game)
    end

    test "returns the expected value when game is in progress", %{game: game} do
      {:ok, game} = Game.start(game)

      refute GameDetails.complete?(game)
    end

    test "returns the expected value when game is complete", %{game: game} do
      {:ok, game} = Game.start(game)
      game = Game.advance_round(game)

      assert GameDetails.complete?(game)
    end
  end

  describe "host?/1" do
    setup do
      game =
        Game.new(
          allow_spectators: true,
          host_id: "game-host",
          host_name: "Example",
          game_mode: :party,
          game_type: :custom,
          max_players: 4,
          max_rounds: 1,
          winning_score_type: :lowest
        )

      %{game: game}
    end

    test "returns the expected value", %{game: game} do
      assert GameDetails.host?(game, "game-host")

      refute GameDetails.host?(game, nil)
      refute GameDetails.host?(game, "invalid")
    end
  end

  describe "user_score_editable?/1" do
    setup do
      game =
        Game.new(
          allow_spectators: true,
          host_id: "game-host",
          host_name: "Example",
          game_mode: :party,
          game_type: :custom,
          max_players: 4,
          max_rounds: 2,
          winning_score_type: :lowest
        )

      %{game: game}
    end

    test "not editable when game hasn't started", %{game: game} do
      refute GameDetails.user_score_editable?(game, "game-host", "game-host", 1)
    end

    test "not editable when game is complete", %{game: game} do
      {:ok, game} = Game.start(game)

      game =
        game
        |> Game.advance_round()
        |> Game.advance_round()

      refute GameDetails.user_score_editable?(game, "game-host", "game-host", 1)
    end

    test "not editable when game is on different round", %{game: game} do
      {:ok, game} = Game.start(game)

      refute GameDetails.user_score_editable?(game, "game-host", "game-host", 2)
    end

    test "not editable when trying to edit another player's score", %{game: game} do
      {:ok, game} = Game.start(game)

      refute GameDetails.user_score_editable?(game, "player1", "player2", 1)
    end

    test "editable when trying to edit another player's score as host", %{game: game} do
      {:ok, game} = Game.start(game)

      assert GameDetails.user_score_editable?(game, "player1", "game-host", 1)
    end

    test "editable when trying to edit own score in party mode", %{game: game} do
      {:ok, game} = Game.start(game)

      assert GameDetails.user_score_editable?(game, "player1", "player1", 1)
    end
  end

  describe "get_status/1" do
    test "returns the expected value" do
      assert GameDetails.get_status(:in_progress) == "In Progress"
      assert GameDetails.get_status(:waiting_for_players) == "Waiting for Players"
      assert GameDetails.get_status(:complete) == "Complete"
    end
  end

  describe "get_join_error_details/1" do
    test "returns the expected value" do
      assert GameDetails.get_join_error_details(:already_exists) ==
               {:player_name, "Player already exists"}

      assert GameDetails.get_join_error_details(:duplicate_name) ==
               {:player_name, "Please select a different name"}

      assert GameDetails.get_join_error_details(:not_found) == {:game_id, "Game not found"}

      assert GameDetails.get_join_error_details(:not_joinable) ==
               {:game_id, "Game not joinable"}
    end
  end

  describe "any_missing_player_round_score?/1" do
    setup do
      game =
        Game.new(
          allow_spectators: true,
          host_id: "game-host",
          host_name: "Example",
          game_mode: :scorekeeper,
          game_type: :custom,
          max_players: 4,
          max_rounds: 2,
          players: ["PlayerTwo"],
          winning_score_type: :lowest
        )

      %{game: game}
    end

    test "true when scores are missing", %{game: game} do
      {:ok, game} = Game.update_score(game, "game-host", 1, 10)
      assert GameDetails.any_missing_player_round_score?(game)
    end

    test "false when no scores are missing", %{game: game} do
      player_two_id =
        game.players
        |> Enum.find(fn %Player{name: name} -> name == "PlayerTwo" end)
        |> Map.get(:id)

      {:ok, game} = Game.update_score(game, "game-host", 1, 10)
      {:ok, game} = Game.update_score(game, player_two_id, 1, 20)

      refute GameDetails.any_missing_player_round_score?(game)
    end
  end

  describe "format_winners/1" do
    test "returns the expected value" do
      assert GameDetails.format_winners(["PlayerOne", "PlayerTwo"]) == "PlayerOne and PlayerTwo"

      assert GameDetails.format_winners(["PlayerOne", "PlayerTwo", "PlayerThree"]) ==
               "PlayerTwo, PlayerThree, and PlayerOne"
    end
  end

  describe "player_total_score/2" do
    setup do
      game =
        Game.new(
          allow_spectators: true,
          host_id: "game-host",
          host_name: "Example",
          game_mode: :scorekeeper,
          game_type: :custom,
          max_players: 4,
          max_rounds: 2,
          players: ["PlayerTwo"],
          winning_score_type: :lowest
        )

      %{game: game}
    end

    test "returns the expected value", %{game: game} do
      player_two_id =
        game.players
        |> Enum.find(fn %Player{name: name} -> name == "PlayerTwo" end)
        |> Map.get(:id)

      {:ok, game} = Game.update_score(game, "game-host", 1, 10)
      {:ok, game} = Game.update_score(game, "game-host", 2, 20)

      assert GameDetails.player_total_score("game-host", game) == 30
      assert GameDetails.player_total_score(player_two_id, game) == 0
    end
  end

  describe "winner/1" do
    setup do
      game =
        Game.new(
          allow_spectators: true,
          host_id: "game-host",
          host_name: "Example",
          game_mode: :scorekeeper,
          game_type: :custom,
          max_players: 4,
          max_rounds: 2,
          players: ["PlayerTwo", "PlayerThree"],
          winning_score_type: :lowest
        )

      player_two_id =
        game.players
        |> Enum.find(fn %Player{name: name} -> name == "PlayerTwo" end)
        |> Map.get(:id)

      player_three_id =
        game.players
        |> Enum.find(fn %Player{name: name} -> name == "PlayerThree" end)
        |> Map.get(:id)

      %{game: game, player_two_id: player_two_id, player_three_id: player_three_id}
    end

    test "single winner with lowest score", %{
      game: game,
      player_two_id: player_two_id,
      player_three_id: player_three_id
    } do
      {:ok, game} = Game.update_score(game, "game-host", 1, 100)
      {:ok, game} = Game.update_score(game, player_two_id, 1, 50)
      {:ok, game} = Game.update_score(game, player_three_id, 1, 10)

      game = Game.advance_round(game)

      {:ok, game} = Game.update_score(game, "game-host", 2, 100)
      {:ok, game} = Game.update_score(game, player_two_id, 2, 50)
      {:ok, game} = Game.update_score(game, player_three_id, 2, 20)

      game = Game.advance_round(game)

      assert GameDetails.winner(game) == %{type: :single, winner: "PlayerThree", score: 30}
    end

    test "single winner with highest score", %{
      game: game,
      player_two_id: player_two_id,
      player_three_id: player_three_id
    } do
      game = %{game | winning_score_type: :highest}

      {:ok, game} = Game.update_score(game, "game-host", 1, 100)
      {:ok, game} = Game.update_score(game, player_two_id, 1, 50)
      {:ok, game} = Game.update_score(game, player_three_id, 1, 10)

      game = Game.advance_round(game)

      {:ok, game} = Game.update_score(game, "game-host", 2, 100)
      {:ok, game} = Game.update_score(game, player_two_id, 2, 50)
      {:ok, game} = Game.update_score(game, player_three_id, 2, 20)

      game = Game.advance_round(game)

      assert GameDetails.winner(game) == %{type: :single, winner: "Example", score: 200}
    end

    test "tie for lowest score", %{
      game: game,
      player_two_id: player_two_id,
      player_three_id: player_three_id
    } do
      {:ok, game} = Game.update_score(game, "game-host", 1, 0)
      {:ok, game} = Game.update_score(game, player_two_id, 1, 50)
      {:ok, game} = Game.update_score(game, player_three_id, 1, 0)

      game = Game.advance_round(game)

      {:ok, game} = Game.update_score(game, "game-host", 2, 10)
      {:ok, game} = Game.update_score(game, player_two_id, 2, 50)
      {:ok, game} = Game.update_score(game, player_three_id, 2, 10)

      game = Game.advance_round(game)

      assert GameDetails.winner(game) == %{
               type: :tie,
               winners: ["Example", "PlayerThree"],
               score: 10
             }
    end

    test "tie for highest score", %{
      game: game,
      player_two_id: player_two_id,
      player_three_id: player_three_id
    } do
      game = %{game | winning_score_type: :highest}

      {:ok, game} = Game.update_score(game, "game-host", 1, 100)
      {:ok, game} = Game.update_score(game, player_two_id, 1, 50)
      {:ok, game} = Game.update_score(game, player_three_id, 1, 110)

      game = Game.advance_round(game)

      {:ok, game} = Game.update_score(game, "game-host", 2, 15)
      {:ok, game} = Game.update_score(game, player_two_id, 2, 50)
      {:ok, game} = Game.update_score(game, player_three_id, 2, 5)

      game = Game.advance_round(game)

      assert GameDetails.winner(game) == %{
               type: :tie,
               winners: ["Example", "PlayerThree"],
               score: 115
             }
    end
  end
end
