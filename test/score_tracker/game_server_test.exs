defmodule ScoreTracker.GameServerTest do
  use ExUnit.Case, async: false

  alias ScoreTracker.{Game, GameServer, Player}
  alias ScoreTracker.GameType.{Ripple, Rummy}

  setup do
    start_supervised!({Agent, fn -> :ets.new(:lobbies, [:named_table, :public, :set]) end})

    on_exit(fn ->
      ScoreTracker.GameSupervisor
      |> DynamicSupervisor.which_children()
      |> Enum.each(fn {_, pid, _, _} ->
        DynamicSupervisor.terminate_child(ScoreTracker.GameSupervisor, pid)
      end)
    end)

    :ok
  end

  describe "create_game/1" do
    test "scorekeeper game with valid options" do
      game_opts = [
        allow_spectators: false,
        host_id: "game-host",
        host_name: "Example",
        game_mode: :scorekeeper,
        game_type: :custom,
        max_players: 4,
        max_rounds: 5,
        players: ["PlayerTwo", "PlayerThree"],
        winning_score_type: :highest
      ]

      game_id = GameServer.create_game(game_opts)
      assert is_binary(game_id)

      {:ok, game} = GameServer.get_game(game_id)

      assert game.game_mode == :scorekeeper
      assert game.game_type == :custom
      assert game.allow_spectators == false
      assert game.max_players == 4
      assert game.max_rounds == 5
      assert game.host_id == "game-host"
      assert game.status == :in_progress
      assert game.round == 1
      assert game.winning_score_type == :highest

      player_names = Enum.map(game.players, &Map.get(&1, :name))
      assert Enum.count(player_names) == 3
      assert "PlayerTwo" in player_names
      assert "PlayerThree" in player_names
      assert "Example" in player_names

      scores = Map.values(game.scores)
      assert Enum.count(scores) == 3
    end

    test "party game with valid options" do
      game_opts = [
        host_id: "game-host",
        host_name: "Example",
        game_mode: :party,
        game_type: :ripple,
        max_players: Ripple.max_players(),
        max_rounds: Ripple.max_rounds(),
        winning_score_type: Ripple.winning_score_type()
      ]

      game_id = GameServer.create_game(game_opts)
      assert is_binary(game_id)

      {:ok, game} = GameServer.get_game(game_id)

      assert game == %Game{
               game_mode: :party,
               game_type: :ripple,
               allow_spectators: true,
               max_players: 6,
               max_rounds: 10,
               history: [],
               host_id: "game-host",
               status: :waiting_for_players,
               round: 1,
               players: [%Player{id: "game-host", name: "Example"}],
               scores: %{"game-host" => %{}},
               winning_score_type: :lowest
             }
    end
  end

  describe "add_player/1" do
    setup do
      party_game_opts = [
        allow_spectators: true,
        host_id: "game-host",
        host_name: "Example",
        game_mode: :party,
        game_type: :ripple,
        max_players: Ripple.max_players(),
        max_rounds: Ripple.max_rounds(),
        winning_score_type: Ripple.winning_score_type()
      ]

      scorekeeper_game_opts = [
        allow_spectators: true,
        host_id: "game-host",
        host_name: "Example",
        game_mode: :scorekeeper,
        game_type: :custom,
        max_players: 4,
        max_rounds: 5,
        players: ["PlayerTwo", "PlayerThree"],
        winning_score_type: :highest
      ]

      %{party_game_opts: party_game_opts, scorekeeper_game_opts: scorekeeper_game_opts}
    end

    test "adds a player to a party game", %{party_game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)

      player_opts = [game_id: game_id, player_id: "player1", player_name: "PlayerOne"]
      :ok = GameServer.add_player(player_opts)

      {:ok, game} = GameServer.get_game(game_id)
      assert Enum.any?(game.players, &match?(%Player{id: "player1", name: "PlayerOne"}, &1))
      assert game.scores["player1"] == %{}
    end

    test "adds a spectator to a scorekeeper game", %{scorekeeper_game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)

      player_id = "player1"
      player_opts = [game_id: game_id, player_id: player_id, player_name: "PlayerOne"]
      :ok = GameServer.add_player(player_opts)

      {:ok, game} = GameServer.get_game(game_id)
      refute Enum.any?(game.players, &match?(%Player{id: ^player_id}, &1))
    end

    test "adds a spectator to a party game", %{party_game_opts: game_opts} do
      # create and start a game to put it into the correct state
      game_id = GameServer.create_game(game_opts)
      {:ok, :in_progress} = GameServer.start_game(game_id)

      player_id = "player1"
      player_opts = [game_id: game_id, player_id: player_id, player_name: "PlayerOne"]
      :ok = GameServer.add_player(player_opts)

      {:ok, game} = GameServer.get_game(game_id)
      refute Enum.any?(game.players, &match?(%Player{id: ^player_id}, &1))
    end

    test "rejects when game not found" do
      player_opts = [game_id: "invalid-game-id", player_id: "player1", player_name: "PlayerOne"]
      assert {:error, :not_found} == GameServer.add_player(player_opts)
    end

    test "rejects player that already exists in a party game", %{party_game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)

      # add the player once so it exists in the game state
      player_opts = [game_id: game_id, player_id: "player1", player_name: "PlayerOne"]
      :ok = GameServer.add_player(player_opts)

      assert {:error, :already_exists} == GameServer.add_player(player_opts)
    end

    test "rejects adding spectator to a scorekeeper game", %{
      scorekeeper_game_opts: game_opts
    } do
      game_opts = Keyword.put(game_opts, :allow_spectators, false)
      game_id = GameServer.create_game(game_opts)

      player_opts = [game_id: game_id, player_id: "player4", player_name: "PlayerFour"]
      assert {:error, :not_joinable} == GameServer.add_player(player_opts)
    end

    test "rejects adding spectator to a party game", %{party_game_opts: game_opts} do
      game_opts = Keyword.put(game_opts, :allow_spectators, false)

      # create and start a game to put it into the correct state
      game_id = GameServer.create_game(game_opts)
      {:ok, :in_progress} = GameServer.start_game(game_id)

      player_opts = [game_id: game_id, player_id: "player4", player_name: "PlayerFour"]
      assert {:error, :not_joinable} == GameServer.add_player(player_opts)
    end
  end

  describe "update_player_score/1" do
    setup do
      game_opts = [
        host_id: "game-host",
        host_name: "Host",
        game_mode: :scorekeeper,
        game_type: :rummy,
        max_players: Rummy.max_rounds(),
        max_rounds: Rummy.max_players(),
        players: ["PlayerTwo"],
        winning_score_type: Rummy.winning_score_type()
      ]

      %{game_opts: game_opts}
    end

    test "updates player score", %{game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)

      score_opts = [game_id: game_id, player_id: "game-host", round: 1, score: 10]
      assert :ok == GameServer.update_player_score(score_opts)

      {:ok, game} = GameServer.get_game(game_id)
      assert 10 == game.scores["game-host"]["1"]
    end

    test "rejects when game not found" do
      score_opts = [game_id: "invalid-game-id", player_id: "game-host", round: 1, score: 10]
      assert {:error, :not_found} == GameServer.update_player_score(score_opts)
    end

    test "rejects when player not found", %{game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)

      score_opts = [game_id: game_id, player_id: "invalid-player-id", round: 1, score: 10]
      assert {:error, :player_not_found} == GameServer.update_player_score(score_opts)
    end
  end

  describe "start_game/1" do
    setup do
      party_game_opts = [
        allow_spectators: true,
        host_id: "game-host",
        host_name: "Example",
        game_mode: :party,
        game_type: :ripple,
        max_players: Ripple.max_players(),
        max_rounds: Ripple.max_rounds(),
        winning_score_type: Ripple.winning_score_type()
      ]

      scorekeeper_game_opts = [
        allow_spectators: true,
        host_id: "game-host",
        host_name: "Example",
        game_mode: :scorekeeper,
        game_type: :custom,
        max_players: 4,
        max_rounds: 5,
        players: ["PlayerTwo", "PlayerThree"],
        winning_score_type: :lowest
      ]

      %{party_game_opts: party_game_opts, scorekeeper_game_opts: scorekeeper_game_opts}
    end

    test "starts a party game", %{party_game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)

      assert {:ok, :in_progress} == GameServer.start_game(game_id)
    end

    test "rejects when game not found" do
      assert {:error, :not_found} == GameServer.start_game("invalid-game-id")
    end

    test "rejects when game type is scorekeeper", %{scorekeeper_game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)

      assert {:error, :invalid_game_mode} == GameServer.start_game(game_id)
    end

    test "rejects when game is already in progress", %{party_game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)

      # start the game once so the game is in progress
      {:ok, :in_progress} = GameServer.start_game(game_id)

      assert {:error, :invalid_game_state} == GameServer.start_game(game_id)
    end
  end

  describe "advance_to_next_round/1" do
    setup do
      game_opts = [
        allow_spectators: true,
        host_id: "game-host",
        host_name: "Example",
        game_mode: :scorekeeper,
        game_type: :custom,
        max_players: 4,
        max_rounds: 2,
        players: ["PlayerTwo", "PlayerThree"],
        winning_score_type: :highest
      ]

      %{game_opts: game_opts}
    end

    test "advances to next round", %{game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)
      assert {:ok, 2} == GameServer.advance_to_next_round(game_id)
    end

    test "marks game as complete when max rounds reached", %{game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)

      # advance game to last round
      {:ok, 2} = GameServer.advance_to_next_round(game_id)

      assert {:ok, 2} == GameServer.advance_to_next_round(game_id)

      {:ok, game} = GameServer.get_game(game_id)
      assert game.status == :complete
    end

    test "rejects when game not found" do
      assert {:error, :not_found} == GameServer.advance_to_next_round("invalid-game-id")
    end
  end

  describe "reset_game/1" do
    setup do
      game_opts = [
        allow_spectators: true,
        host_id: "game-host",
        host_name: "Example",
        game_mode: :scorekeeper,
        game_type: :custom,
        max_players: 4,
        max_rounds: 2,
        players: ["PlayerTwo", "PlayerThree"],
        winning_score_type: :lowest
      ]

      %{game_opts: game_opts}
    end

    test "resets completed game", %{game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)
      {:ok, 2} = GameServer.advance_to_next_round(game_id)
      {:ok, 2} = GameServer.advance_to_next_round(game_id)
      {:ok, game} = GameServer.get_game(game_id)

      player_two_id =
        game.players
        |> Enum.find(fn %Player{name: name} -> name == "PlayerTwo" end)
        |> Map.get(:id)

      player_three_id =
        game.players
        |> Enum.find(fn %Player{name: name} -> name == "PlayerThree" end)
        |> Map.get(:id)

      assert game.status == :complete
      assert game.round == 2

      :ok = GameServer.reset_game(game_id)

      {:ok, reset_game} = GameServer.get_game(game_id)

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
      assert reset_game.winning_score_type == game.winning_score_type
    end

    test "rejects when game not found" do
      assert {:error, :not_found} == GameServer.reset_game("invalid-game-id")
    end

    test "rejects when scorekeeper game is not completed", %{game_opts: game_opts} do
      game_id = GameServer.create_game(game_opts)

      assert {:error, :invalid_game_state} == GameServer.reset_game(game_id)
    end

    test "rejects when party game is not started", %{game_opts: game_opts} do
      game_opts = Keyword.put(game_opts, :game_mode, :party)
      game_id = GameServer.create_game(game_opts)

      assert {:error, :invalid_game_state} == GameServer.reset_game(game_id)
    end

    test "rejects when party game is not completed", %{game_opts: game_opts} do
      game_opts = Keyword.put(game_opts, :game_mode, :party)
      game_id = GameServer.create_game(game_opts)
      {:ok, _} = GameServer.start_game(game_id)

      assert {:error, :invalid_game_state} == GameServer.reset_game(game_id)
    end
  end

  describe "get_game/1" do
    test "gets a game's state" do
      game_opts = [
        host_id: "game-host",
        host_name: "Example",
        game_mode: :party,
        game_type: :rummy,
        max_players: Rummy.max_players(),
        max_rounds: Rummy.max_rounds(),
        winning_score_type: Rummy.winning_score_type()
      ]

      game_id = GameServer.create_game(game_opts)

      {:ok, game} = GameServer.get_game(game_id)

      assert game == %Game{
               game_mode: :party,
               game_type: :rummy,
               allow_spectators: true,
               max_players: 8,
               max_rounds: 8,
               history: [],
               host_id: "game-host",
               status: :waiting_for_players,
               round: 1,
               players: [%Player{id: "game-host", name: "Example"}],
               scores: %{"game-host" => %{}},
               winning_score_type: :lowest
             }
    end

    test "rejects when game not found" do
      assert {:error, :not_found} == GameServer.get_game("invalid-game-id")
    end
  end

  describe "idle timeout" do
    test "game process shuts down after idle timeout" do
      game_opts = [
        host_id: "game-host",
        host_name: "Example",
        game_mode: :scorekeeper,
        game_type: :custom,
        max_players: 4,
        max_rounds: 5,
        players: [],
        winning_score_type: :highest
      ]

      game_id = GameServer.create_game(game_opts)

      # Monitor the process before triggering shutdown
      [{pid, _}] = Registry.lookup(ScoreTracker.GameRegistry, game_id)
      ref = Process.monitor(pid)

      # Send a timeout message to simulate idle timeout
      send(pid, :timeout)

      # Wait for process to shut down with the expected reason
      assert_receive {:DOWN, ^ref, :process, ^pid, {:shutdown, :idle_timeout}}

      # The game should still be loadable from storage (cold start)
      {:ok, _game} = GameServer.get_game(game_id)
    end
  end
end
