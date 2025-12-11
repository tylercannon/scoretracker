defmodule ScoreTracker.GameTest do
  use ExUnit.Case, async: true

  alias ScoreTracker.{Game, Player}
  alias ScoreTracker.GameType.{Ripple, Rummy}

  describe "new/1" do
    test "creates scorekeeper game with players" do
      opts = [
        allow_spectators: false,
        host_id: "game-host",
        host_name: "Example",
        game_mode: :scorekeeper,
        game_type: :custom,
        max_players: 4,
        max_rounds: 5,
        players: ["PlayerTwo", "PlayerThree"]
      ]

      game = Game.new(opts)
      player_names = Enum.map(game.players, &Map.get(&1, :name))

      refute game.allow_spectators
      assert is_nil(game.custom_name)
      assert game.host_id == "game-host"
      assert game.game_mode == :scorekeeper
      assert game.game_type == :custom
      assert game.max_players == 4
      assert game.max_rounds == 5
      assert game.round == 1
      assert game.status == :in_progress

      assert Enum.count(game.scores) == 3
      assert Enum.count(player_names) == 3
      assert "Example" in player_names
      assert "PlayerTwo" in player_names
      assert "PlayerThree" in player_names
    end

    test "creates party game with default values" do
      opts = [
        host_id: "game-host",
        host_name: "Example",
        game_mode: :party,
        game_type: :ripple,
        max_players: Ripple.max_players(),
        max_rounds: Ripple.max_rounds()
      ]

      game = Game.new(opts)

      assert game == %Game{
               allow_spectators: true,
               custom_name: nil,
               game_mode: :party,
               game_type: :ripple,
               host_id: "game-host",
               max_players: 6,
               max_rounds: 10,
               players: [%Player{id: "game-host", name: "Example"}],
               round: 1,
               scores: %{"game-host" => %{}},
               status: :waiting_for_players
             }
    end

    test "creates custom game with no name" do
      opts = [
        host_id: "game-host",
        host_name: "Example",
        game_mode: :party,
        game_type: :custom,
        max_players: 3,
        max_rounds: 4
      ]

      game = Game.new(opts)

      assert game == %Game{
               allow_spectators: true,
               custom_name: nil,
               game_mode: :party,
               game_type: :custom,
               host_id: "game-host",
               max_players: 3,
               max_rounds: 4,
               players: [%Player{id: "game-host", name: "Example"}],
               round: 1,
               scores: %{"game-host" => %{}},
               status: :waiting_for_players
             }
    end

    test "creates custom game with name" do
      opts = [
        custom_name: "MyGame",
        host_id: "game-host",
        host_name: "Example",
        game_mode: :party,
        game_type: :custom,
        max_players: 3,
        max_rounds: 4
      ]

      game = Game.new(opts)

      assert game == %Game{
               allow_spectators: true,
               custom_name: "MyGame",
               game_mode: :party,
               game_type: :custom,
               host_id: "game-host",
               max_players: 3,
               max_rounds: 4,
               players: [%Player{id: "game-host", name: "Example"}],
               round: 1,
               scores: %{"game-host" => %{}},
               status: :waiting_for_players
             }
    end
  end

  describe "add_player/3" do
    setup do
      party_game_opts = [
        allow_spectators: true,
        host_id: "game-host",
        host_name: "Example",
        game_mode: :party,
        game_type: :ripple,
        max_players: Ripple.max_players(),
        max_rounds: Ripple.max_rounds()
      ]

      scorekeeper_game_opts = [
        allow_spectators: true,
        host_id: "game-host",
        host_name: "Example",
        game_mode: :scorekeeper,
        game_type: :custom,
        max_players: 4,
        max_rounds: 5,
        players: ["PlayerTwo", "PlayerThree"]
      ]

      %{party_game_opts: party_game_opts, scorekeeper_game_opts: scorekeeper_game_opts}
    end

    test "adds a player to party game", %{party_game_opts: party_game_opts} do
      {:ok, :player, updated_game} =
        party_game_opts
        |> Game.new()
        |> Game.add_player("player2", "PlayerTwo")

      assert Enum.count(updated_game.players) == 2

      assert Enum.any?(
               updated_game.players,
               &match?(%Player{id: "player2", name: "PlayerTwo"}, &1)
             )

      assert updated_game.scores["player2"] == %{}
    end

    test "adds a player to party game when spectators aren't allowed", %{
      party_game_opts: party_game_opts
    } do
      {:ok, :player, updated_game} =
        party_game_opts
        |> Keyword.put(:allow_spectators, false)
        |> Game.new()
        |> Game.add_player("player2", "PlayerTwo")

      assert Enum.count(updated_game.players) == 2

      assert Enum.any?(
               updated_game.players,
               &match?(%Player{id: "player2", name: "PlayerTwo"}, &1)
             )

      assert updated_game.scores["player2"] == %{}
    end

    test "adds a spectator to scorekeeper game", %{scorekeeper_game_opts: scorekeeper_game_opts} do
      {:ok, :spectator, game} =
        scorekeeper_game_opts
        |> Game.new()
        |> Game.add_player("spectator1", "Observer")

      refute Enum.any?(game.players, &match?(%Player{id: "spectator1"}, &1))
      refute Map.has_key?(game.scores, "spectator1")
    end

    test "adds a spectator to an in-progress party game", %{party_game_opts: party_game_opts} do
      {:ok, game} =
        party_game_opts
        |> Game.new()
        |> Game.start()

      {:ok, :spectator, game} = Game.add_player(game, "spectator1", "Observer")

      refute Enum.any?(game.players, &match?(%Player{id: "spectator1"}, &1))
    end

    test "rejects duplicate player", %{party_game_opts: party_game_opts} do
      {:ok, :player, game} =
        party_game_opts
        |> Game.new()
        |> Game.add_player("player1", "Player")

      assert {:error, :already_exists} = Game.add_player(game, "player1", "Player")
    end

    test "rejects duplicate player name in party game", %{party_game_opts: party_game_opts} do
      {:ok, :player, game} =
        party_game_opts
        |> Game.new()
        |> Game.add_player("player1", "Player")

      assert {:error, :duplicate_name} = Game.add_player(game, "player2", "Player")
    end

    test "rejects adding player when spectators aren't allowed in a scorekeeper game", %{
      scorekeeper_game_opts: scorekeeper_game_opts
    } do
      game =
        scorekeeper_game_opts
        |> Keyword.put(:allow_spectators, false)
        |> Game.new()

      assert {:error, :not_joinable} = Game.add_player(game, "player1", "Player")
    end

    test "rejects adding player to in-progress party game when spectators aren't allowed", %{
      party_game_opts: party_game_opts
    } do
      {:ok, game} =
        party_game_opts
        |> Keyword.put(:allow_spectators, false)
        |> Game.new()
        |> Game.start()

      assert {:error, :not_joinable} = Game.add_player(game, "player1", "Player")
    end
  end

  describe "update_score/4" do
    setup do
      game_opts = [
        host_id: "game-host",
        host_name: "Host",
        game_mode: :scorekeeper,
        game_type: :rummy,
        max_players: Rummy.max_rounds(),
        max_rounds: Rummy.max_players(),
        players: ["PlayerTwo"]
      ]

      %{game_opts: game_opts}
    end

    test "updates player score for valid player", %{game_opts: game_opts} do
      game = Game.new(game_opts)

      assert {:ok, updated_game} = Game.update_score(game, "game-host", 1, 10)
      assert updated_game.scores["game-host"]["1"] == 10
    end

    test "updates score for multiple rounds", %{game_opts: game_opts} do
      game = Game.new(game_opts)

      {:ok, game} = Game.update_score(game, "game-host", 1, 10)
      {:ok, game} = Game.update_score(game, "game-host", 2, 20)
      {:ok, game} = Game.update_score(game, "game-host", 3, 15)

      assert game.scores["game-host"]["1"] == 10
      assert game.scores["game-host"]["2"] == 20
      assert game.scores["game-host"]["3"] == 15
    end

    test "rejects update for non-existent player", %{game_opts: game_opts} do
      game = Game.new(game_opts)

      assert {:error, :player_not_found} = Game.update_score(game, "nonexistent", 1, 10)
    end

    test "overwrites existing score for same round", %{game_opts: game_opts} do
      game = Game.new(game_opts)

      {:ok, game} = Game.update_score(game, "game-host", 1, 10)
      {:ok, game} = Game.update_score(game, "game-host", 1, 25)

      assert game.scores["game-host"]["1"] == 25
    end
  end

  describe "start/1" do
    setup do
      party_game_opts = [
        allow_spectators: true,
        host_id: "game-host",
        host_name: "Example",
        game_mode: :party,
        game_type: :ripple,
        max_players: Ripple.max_players(),
        max_rounds: Ripple.max_rounds()
      ]

      scorekeeper_game_opts = [
        allow_spectators: true,
        host_id: "game-host",
        host_name: "Example",
        game_mode: :scorekeeper,
        game_type: :custom,
        max_players: 4,
        max_rounds: 5,
        players: ["PlayerTwo", "PlayerThree"]
      ]

      %{party_game_opts: party_game_opts, scorekeeper_game_opts: scorekeeper_game_opts}
    end

    test "starts party game from waiting state", %{party_game_opts: party_game_opts} do
      game = Game.new(party_game_opts)

      assert game.status == :waiting_for_players

      assert {:ok, started_game} = Game.start(game)
      assert started_game.status == :in_progress
    end

    test "rejects starting scorekeeper game", %{scorekeeper_game_opts: scorekeeper_game_opts} do
      game = Game.new(scorekeeper_game_opts)

      assert {:error, :invalid_game_mode} = Game.start(game)
    end

    test "rejects starting an in-progress party game", %{party_game_opts: party_game_opts} do
      {:ok, started_game} =
        party_game_opts
        |> Game.new()
        |> Game.start()

      assert {:error, :invalid_game_state} = Game.start(started_game)
    end

    test "rejects starting completed game", %{party_game_opts: party_game_opts} do
      {:ok, started_game} =
        party_game_opts
        |> Keyword.put(:max_rounds, 1)
        |> Game.new()
        |> Game.start()

      completed_game = Game.advance_round(started_game)

      assert completed_game.status == :complete
      assert {:error, :invalid_game_state} = Game.start(completed_game)
    end
  end

  describe "advance_round/1" do
    setup do
      game_opts = [
        allow_spectators: true,
        host_id: "game-host",
        host_name: "Example",
        game_mode: :scorekeeper,
        game_type: :custom,
        max_players: 4,
        max_rounds: 2,
        players: ["PlayerTwo", "PlayerThree"]
      ]

      %{game_opts: game_opts}
    end

    test "advances to next round", %{game_opts: game_opts} do
      game = Game.new(game_opts)

      assert game.round == 1

      updated_game = Game.advance_round(game)

      assert updated_game.round == 2
    end

    test "marks game complete when reaching max rounds", %{game_opts: game_opts} do
      game = Game.new(game_opts)

      # advance to last round
      game = Game.advance_round(game)

      assert game.round == 2

      # advance to completed state
      game = Game.advance_round(game)

      assert game.round == 2
      assert game.status == :complete
    end

    test "fills missing scores with 0 before advancing", %{game_opts: game_opts} do
      {:ok, game} =
        game_opts
        |> Game.new()
        |> Game.update_score("game-host", 1, 10)

      updated_game = Game.advance_round(game)

      player_two_id =
        game.players
        |> Enum.find(fn %Player{name: name} -> name == "PlayerTwo" end)
        |> Map.get(:id)

      player_three_id =
        game.players
        |> Enum.find(fn %Player{name: name} -> name == "PlayerThree" end)
        |> Map.get(:id)

      assert updated_game.scores["game-host"]["1"] == 10
      assert updated_game.scores[player_two_id]["1"] == 0
      assert updated_game.scores[player_three_id]["1"] == 0
    end

    test "advances through multiple rounds correctly", %{game_opts: game_opts} do
      game =
        game_opts
        |> Keyword.put(:max_rounds, 4)
        |> Game.new()

      game = Game.advance_round(game)
      assert game.round == 2

      game = Game.advance_round(game)
      assert game.round == 3

      game = Game.advance_round(game)
      assert game.round == 4

      game = Game.advance_round(game)
      assert game.round == 4
      assert game.status == :complete
    end
  end

  describe "reset/1" do
    setup do
      game_opts = [
        allow_spectators: true,
        host_id: "game-host",
        host_name: "Example",
        game_mode: :scorekeeper,
        game_type: :custom,
        max_players: 4,
        max_rounds: 2,
        players: ["PlayerTwo", "PlayerThree"]
      ]

      %{game_opts: game_opts}
    end

    test "resets completed game to initial state", %{game_opts: game_opts} do
      game = Game.new(game_opts)

      player_two_id =
        game.players
        |> Enum.find(fn %Player{name: name} -> name == "PlayerTwo" end)
        |> Map.get(:id)

      player_three_id =
        game.players
        |> Enum.find(fn %Player{name: name} -> name == "PlayerThree" end)
        |> Map.get(:id)

      {:ok, game} = Game.update_score(game, "game-host", 1, 10)
      {:ok, game} = Game.update_score(game, player_two_id, 1, 20)
      {:ok, game} = Game.update_score(game, player_three_id, 1, 30)

      game =
        game
        |> Game.advance_round()
        |> Game.advance_round()

      assert game.status == :complete
      assert game.round == 2
      assert game.scores["game-host"]["1"] == 10
      assert game.scores[player_two_id]["1"] == 20
      assert game.scores[player_three_id]["1"] == 30

      {:ok, reset_game} = Game.reset(game)

      assert reset_game.allow_spectators
      assert reset_game.game_mode == game.game_mode
      assert reset_game.game_type == game.game_type
      assert reset_game.host_id == game.host_id
      assert reset_game.max_players == game.max_players
      assert reset_game.max_rounds == game.max_rounds
      assert reset_game.players == game.players
      assert reset_game.status == :in_progress
      assert reset_game.round == 1
      assert reset_game.scores["game-host"] == %{}
      assert reset_game.scores[player_two_id] == %{}
      assert reset_game.scores[player_three_id] == %{}
    end

    test "rejects resetting scorekeeper game that is not completed", %{game_opts: game_opts} do
      game = Game.new(game_opts)

      assert {:error, :invalid_game_state} = Game.reset(game)
    end

    test "rejects resetting party game that is not started", %{game_opts: game_opts} do
      game =
        game_opts
        |> Keyword.put(:game_mode, :party)
        |> Game.new()

      assert {:error, :invalid_game_state} = Game.reset(game)
    end

    test "rejects resetting party game that is not completed", %{game_opts: game_opts} do
      {:ok, game} =
        game_opts
        |> Keyword.put(:game_mode, :party)
        |> Game.new()
        |> Game.start()

      assert {:error, :invalid_game_state} = Game.reset(game)
    end
  end

  describe "from_json/1" do
    setup do
      game =
        Game.new(
          host_id: "game-host",
          host_name: "Example",
          game_mode: :scorekeeper,
          game_type: :custom,
          max_players: 4,
          max_rounds: 5
        )

      %{game: game}
    end

    test "Correctly encodes a game", %{game: game} do
      assert game |> Jason.encode!() |> Jason.decode!() == %{
               "status" => "in_progress",
               "round" => 1,
               "game_mode" => "scorekeeper",
               "game_type" => "custom",
               "allow_spectators" => true,
               "max_players" => 4,
               "max_rounds" => 5,
               "custom_name" => nil,
               "host_id" => "game-host",
               "players" => [%{"id" => "game-host", "name" => "Example"}],
               "scores" => %{"game-host" => %{}}
             }
    end

    test "Correctly decodes a game", %{game: game} do
      {:ok, decoded} =
        game
        |> Jason.encode!()
        |> Game.from_json()

      assert decoded == game
    end
  end
end
